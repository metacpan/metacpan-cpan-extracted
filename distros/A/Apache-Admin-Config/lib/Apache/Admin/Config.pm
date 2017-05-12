package Apache::Admin::Config;

use 5.005;
use strict;
use FileHandle;

$Apache::Admin::Config::VERSION = '0.95';
$Apache::Admin::Config::DEBUG   = 0;

=pod

=head1 NAME

Apache::Admin::Config - A module to read/write Apache like configuration files

=head1 SYNOPSIS

    use Apache::Admin::Config;

    # Parse an apache configuration file

    my $conf = new Apache::Admin::Config "/path/to/config_file.conf"
        or die $Apache::Admin::Config::ERROR;

    my $directive = $conf->directive('documentroot');

    print $directive->name;   # "documentroot"
    print $directive->value;  # "/my/document/root"
    print $directive->type;   # "directive"

    $directive->isin($conf);  # true

    $directive->delete;

    # print the directive list

    foreach($conf->directive())
    {
        print $_->name, "\n";
    }

    # print the virtualhost list

    print $_->section('servername')->value(), "\n"
      foreach $conf->section(-name => "virtualhost");

    # add a directive in all virtualhosts

    foreach($conf->section(-name => "virtualhost"))
    {
        $_->add_directive(php_admin_value => 'open_basedir "/path"');
    }

    # Deleting all "AddType" directives

    $_->delete for $conf->directive("AddType");

    # saving changes in place

    $conf->save;

=head1 DESCRIPTION

C<Apache::Admin::Config> provides an object oriented interface for
reading and writing Apache-like configuration files without affecting
comments, indentation, or truncated lines.

You can easily extract informations from the apache configuration, or
manage htaccess files.

I wrote this class because I work for an IPP, and we often manipulate
apache configuration files for adding new clients, activate some
features or un/locking directories using htaccess, etc. It can also be
useful for writing some one-shoot migrations scripts in few lines.

=head1 METHODES

=head2 new

    $obj = new Apache::Admin::Config [/path/to/file|handle],
      [-indent => $integer], ['-create'], ['-no-comment-grouping'],
      ['-no-blank-grouping']

Create or read, if given in argument, an apache like configuration
file, and return an Apache::Admin::Config instence.

Arguments:

=over 4

=item I<C</path/to/file>>

Path to the configuration file to parse. If none given, create a new
one.

=item I<C<handle>>

Instead of specify a path to a file, you can give a reference to an
handle that point to an already openned file. You can do this like
this :

    my $obj = new Apache::Admin::Config (\*MYHANDLE);

=item I<B<-indent>> =E<gt> I<$integer>

If greater than 0, activates the indentation on added lines, the
integer tell how many spaces you went per level of indentation
(suggest 4). A negative value means padding with tabulation(s).

=item I<B<-create>>

If present and path to an unexisting file is given, don't return an
error.

=item I<B<-no-comment-grouping>>

When there are several successive comment-lines, if comment grouping
is enabled only one comment item is created.

If present, disable comment grouping at parsing time. Enabled by
default.

=item I<B<-no-blank-grouping>>

Same as comment grouping but for blank lines.

=back

=cut

# We wrap the whole module part because we manipulate a tree with
# circular references. Because of the way perl's garbage collector
# works, we have to isolate circular reference in another package to
# be able to destroy circular reference before the garbage collector
# try to destroy the tree.  Without this mechanism, the DESTROY event
# will never be called.

sub new
{
    my $proto = shift;
    my $class = ref $proto || $proto;
    my $self  = {};
    bless $self, $class;

    my $htaccess = shift;

    my $tree = $self->{tree} = new Apache::Admin::Config::Tree(@_)
      or return;

    if(defined $htaccess)
    {
        $tree->_load($htaccess) || return undef;
    }
    else # if htaccess doesn't exists, init new one
    {
        $tree->_init || return undef;
    }
 
    return $self;
}

=pod

=head2 save

    $obj->save(['/path/to/file'|HANDLE], ['-reformat'])

Write modifications to the configuration file. If a path to a file is
given, save the modification to this file instead. You also can give a
reference to a filehandle like this :

    $conf->save(\*MYHANDLE) or die($conf->error());

Note: If you invoke save() on an object instantiated with a filehandle,
you should emptied it before. Keep in mind that the constructor don't
seek the FH to the begin neither before nor after reading it.

=cut

sub save
{
    my $reformat =
      Apache::Admin::Config::Tree::_get_arg(\@_, '-reformat!');

    my($self, $saveas) = @_;

    my $htaccess =
      defined $saveas ? $saveas : $self->{tree}->{htaccess};

    return $self->_set_error("you have to specify a location for writing configuration")
        unless defined $htaccess;

    my $fh;

    if(ref $htaccess eq 'GLOB')
    {
        $fh = $htaccess;
    }
    else
    {
        $fh = new FileHandle(">$htaccess")
            or return $self->_set_error("can't open `$htaccess' file for read");
    }

    print $fh $reformat ? $self->dump_reformat : $self->dump_raw;

    return 1;
}



sub AUTOLOAD
{
    # redirect all method to the right package
    my $self  = shift;
    my($func) = $Apache::Admin::Config::AUTOLOAD =~ /[^:]+$/g;
    return $self->{tree}->$func(@_);
}

sub DESTROY
{
    shift->{tree}->destroy;
}

package Apache::Admin::Config::Tree;

use strict;
use Carp;
use FileHandle;
use overload nomethod => \&to_string;


sub new
{
    my $proto = shift;
    my $class = ref $proto || $proto;
    my $self  = {};
    bless($self, $class);

    $self->{indent} = _get_arg(\@_, '-indent');
    $self->{create} = _get_arg(\@_, '-create!');

    $self->{'comment-grouping'} =
      ! _get_arg(\@_, '-no-comment-grouping!');
    $self->{'blank-grouping'} =
      ! _get_arg(\@_, '-no-blank-grouping!');

    # init the tree
    $self->{type}    = 'section';
    $self->{parent}  = undef;
    $self->{children}  = [];

    return($self);
}

=pod

=head2 dump_raw

    $obj->dump_raw

Returns the configuration file as same as it will be if it was saved
in a file with the B<save()> method. If you don't call this method
from the top level section, it returns the part of the configuration
file that is under the object's context.

=cut

sub dump_raw
{
    my($self) = @_;
    return join '', $self->{raw}||'', $self->_deploy(), $self->{raw2}||'';
}

=pod

=head2 dump_reformat

  $obj->dump_raw

Same as dump_raw(), but reformat each line. Usefull used with -indent
constructor parameter.

=cut

sub dump_reformat
{
    my($self) = @_;
    my $string = '';
    foreach($self->select())
    {
        if($_->type eq 'section')
        {
            $string .= $self->write_section($_->name, $_->value);
            $string .= $_->dump_reformat();
            $string .= $self->write_section_closing($_->name);
        }
        else
        {
            # is it perl 5.0004 compatible ??
            my $method = "write_".$_->type;
            my $name;
            if($_->type eq 'directive')
            {
                $name = $_->name;
            }
            elsif($_->type eq 'comment')
            {
                $name = $_->value;
            }
            elsif($_->type eq 'blank')
            {
                $name = $_->{length};
            }

            my $value = defined $_->value ? $_->value : '';
            $string .= $self->$method($name||'', $value);
        }
    }

    return $string;
}

=pod

=head2 select

    @result = $obj->select
    (
        [-type  => $type],
        [-name  => $name],
        [-value => $value],
        [-which => $index],
    );

    @directives    = $obj->select('directive');
    @sections_foo  = $obj->select('section', 'Foo');

This method search in the current context for items (directives, sections,
comments...) that correspond to a properties given by arguments. It returns
a B<list> of matched nods.

This method can only be called on an object of type "section". This
method search only for elements in the section pointed by object, and
isn't recursive. So elements B<in> sub-sections of current section
aren's seek (it's not a bug).

Arguments:

=over 4

=item B<C<type>>

Selects item(s) of C<type> type.

=item B<C<name>>

Selects item(s) with C<name> name.

=item B<C<value>>

Selects item(s) with C<value> value.

=item B<C<which>>

Instead of returning a list of items, returns only a single one
pointed by index given to the -which option. Caution, returns an empty
string if none selected, so don't cascade your methodes calls like
$obj->select(-which=>0)->name. Index starts at 0.

=back

Method returns a list of item(s) founds. Each items is an
Apache::Admin::Config object with same methods but pointing to a
different part of the tree.

=cut

sub select
{
    my $self = shift;

    my $which = _get_arg(\@_, '-which');

    my %args;
    $args{type}  = _get_arg(\@_, '-type')  || undef;
    $args{name}  = _get_arg(\@_, '-name')  || undef;
    $args{value} = _get_arg(\@_, '-value') || undef;

    # accepting old style arguments for backward compatibilitie
    $args{type}  = shift unless defined $args{type};
    $args{name}  = shift unless defined $args{name};
    $args{value} = shift unless defined $args{value};

    # _get_arg return undef on error or empty string on not founded rule
    return $self->_set_error('malformed arguments')
        if not defined $which; 
    # $which isn't an integer
    return $self->_set_error('error in -which argument: not an integer')
        if $which =~ /[^\d\-]/;
    return $self->_set_error('too many arguments')
        if @_;
    return $self->_set_error('method not allowed')
        unless $self->{type} eq 'section';

    $args{name}  = lc($args{name})  if defined $args{name};
    $args{value} = lc($args{value}) if defined $args{value};

    my @children = @{$self->{children}};

    my $n = 0;
    my @items;
    # pre-select fields to test on each objects
    my @field_to_test = 
        grep(defined $args{$_}, qw(type name value));

    foreach my $item (@children)
    {
        my $match = 1;
        # for all given arguments, we test if it matched
        # for missing aguments, match is always true
        foreach(@field_to_test)
        {
            if(defined $item->{$_})
            {
                $match = $args{$_} eq lc($item->{$_});
            }
            else
            {
                $match = 0;
            }
            last unless $match;
        }

        if($match)
        {
            push(@items, $item);
        }
    }

    if(length $which)
    {
        return defined overload::StrVal($items[$which]) ? $items[$which] : '';
    }
    else
    {
        # We don't return just @items but transfort it in a list
        # because in scalar context, returning an array is same as
        # returning the number of ellements in it, but we want return
        # the _last_ element like a list do une scalar context. If you
        # have a better/nicer idea...
        return(@items ? @items[0 .. $#items] : ());
    }
}

=pod

=head2 directive

    @directives = $obj->directive(args...)

Same as calling select('directive', args...)

=cut

sub directive
{
    my $self = shift;
    $self->select('directive', @_);
}

=pod

=head2 section

    @sections = $obj->section(args...)

Same as calling select('section', args...)

=cut

sub section
{
    my $self = shift;
    $self->select('section', @_);
}

=pod

=head2 comment

    @comments = $obj->comment(args...)

Same as calling select('comment', args...)

=cut

sub comment
{
    my $self = shift;
    $self->select('comment', undef, @_);
}

=pod

=head2 blank

    @blanks = $obj->blank(args...)

Same as calling select('blank', args...)

=cut

sub blank
{
    my $self = shift;
    $self->select('blank', @_);
}

sub indent
{
    my($self) = @_;
    my $parent = $self->parent;
    my $level = 0;
    my $indent = $self->top->{indent} || 0;
    while(defined $parent)
    {
        $parent = $parent->parent;
        $level++;
    }

    return($level
        ? (($indent > 0 ? ' ' : "\t") x (abs $indent)) x $level
        : '');
}

=pod

=head2 set_write_directive

  $conf->set_write_directive($code);

Replace the directive writing engine by you own code. Code is call for
adding new directives, or when you tell Apache::Admin::Config to
reformat the whole configuration file. See B<save()> and
B<dump_reformat()> methods for more details.

Your handler receives 3 arguments : $self, $name and $value. You can
call the C<indent()> method to get the number of spaces to put before
the current line (see B<indent()> methods for more details)

  $conf->set_write_directive(sub
  {
      my($self, $name, $value) = @_;
      return $self->indent . "$name $value\n";
  }

=cut

sub write_directive
{
    my($self) = @_;
    my $code = $self->_get_var('_write_directive') || \&default_write_directive;
    &$code(@_);
}

sub set_write_directive
{
    my($self, $code) = @_;
    $self->{_write_directive} = $code;
}

sub default_write_directive
{
    my($self, $name, $value) = @_;
    return undef unless defined $name;
    $value = defined $value ? $value : '';
    return($self->indent."$name $value\n");
}

=pod

=head2 set_write_section

  $conf->set_write_section($code);

Same as set_write_directive() but for section.

Your handler receives 3 arguments: $self, $name and $value. You can
call the C<indent()> method to get the number of spaces to put before
the current line (see B<indent()> methods for more details)

  $conf->set_write_section(sub
  {
      my($self, $name, $value) = @_;
      return $self->indent . "<$name $value>\n";
  }

=cut

sub write_section
{
    my($self) = @_;
    my $code = $self->_get_var('_write_section') || \&default_write_section;
    &$code(@_);
}

sub set_write_section
{
    my($self, $code) = @_;
    $self->{_write_section} = $code;
}

sub default_write_section
{
    my($self, $name, $value) = @_;
    return($self->indent."<$name $value>\n");
}

=pod

=head2 set_write_section_closing

  $conf->set_write_section_closing($code);

Same as set_write_directive() but for end of sections.

Your handler receives 2 arguments: $self and $name. You can call the
C<indent()> method to get the number of spaces to put before the
current line (see B<indent()> methods for more details)

  $conf->set_write_section_closing(sub
  {
      my($self, $name) = @_;
      return $self->indent . "</$name>\n";
  }

=cut

sub write_section_closing
{
    my($self) = @_;
    my $code = $self->_get_var('_write_section_closing') || \&default_write_section_closing;
    &$code(@_);
}

sub set_write_section_closing
{
    my($self, $code) = @_;
    $self->{_write_section_closing} = $code;
}

sub default_write_section_closing
{
    my($self, $name) = @_;
    return($self->indent."</$name>\n");
}

=pod

=head2 set_write_comment

  $conf->set_write_comment($code);

Same as set_write_directive() but for comments.

Your handler receives 2 arguments: $self and $value. You can call the
C<indent()> method to get the number of spaces to put before the
current line (see B<indent()> methods for more details)

  $conf->set_write_comment(sub
  {
      my($self, $value) = @_;
      # handle comment grouping
      $value =~ s/\n/\n# /g;
      return $self->indent . join('#', split(/\n/, $value));
  }

=cut

sub write_comment
{
    my($self) = @_;
    my $code = $self->_get_var('_write_comment') || \&default_write_comment;
    &$code(@_);
}

sub set_write_comment
{
    my($self, $code) = @_;
    $self->{_write_comment} = $code;
}

sub default_write_comment
{
    my($self, $value) = @_;
    $value =~ s/\n/\n# /g;
    return $self->indent."# $value\n";
}


=pod

=head2 set_write_blank

  $conf->set_write_blank($code);

Same as set_write_directive() but for blank lines.

Your handler receives 2 arguments: $self and $number.

  $conf->set_write_blank(sub
  {
      my($self, $number) = @_;
      return $number x "\n";
  }

=cut

sub write_blank
{
    my($self) = @_;
    my $code = $self->_get_var('_write_blank') || \&default_write_blank;
    &$code(@_);
}

sub set_write_blank
{
    my($self, $code) = @_;
    $self->{_write_blank} = $code;
}

sub default_write_blank
{
    my($self, $number) = @_;
    return "\n" x $number;
}


=pod

=head2 add

    $item = $obj->add
    (
        $type|$item, [$name], [$value],
        [-before => $target | -after => $target | '-ontop' | '-onbottom']
    );

    $item = $obj->add('section', foo => 'bar', -after => $conf_item_object);
    $item = $obj->add('comment', 'a simple comment', '-ontop');

Add a line of type I<$type> with name I<foo> and value I<bar> in the
context pointed by B<$object>.

Aguments:

=over 4

=item B<C<type>>

Type of object to add (directive, section, comment or blank).

=item B<C<name>>

Only relevant for directives and sections.

=item B<C<value>>

For directive and section, it defines the value, for comments it
defined the text.

=item B<C<-before>> =E<gt> I<target>

Inserts item one line before I<target>. I<target> _have_ to be in the
same context

=item B<C<-after>> =E<gt> I<target>

Inserts item one line after I<target>. I<target> _have_ to be in the
same context

=item B<C<-ontop>>

Insert item on the fist line of current context;

=item B<C<-onbottom>>

Iinsert item on the last line of current context;

=back

Returns the added item

=cut

sub add
{
    my $self = shift;

    my($target, $where) = _get_arg(\@_, '-before|-after|-ontop!|-onbottom!');

    $target = $target->{tree} if ref $target eq 'Apache::Admin::Config';

    # _get_arg return undef on error or empty string on not founded rule
    return($self->_set_error('malformed arguments'))
        if(not defined $target);
    return($self->_set_error('too many arguments'))
        if(@_ > 3);
    my($type, $name, $value) = @_;

    return($self->_set_error('wrong type for destination'))
        unless($self->{type} eq 'section');

    $where = defined $where ? $where : '-onbottom'; # default behavior
    if(($where eq '-before' || $where eq '-after') && defined $target)
    {
        return $self->_set_error("target `$target' isn\'t an object")
            unless ref $target && $target->isa('Apache::Admin::Config::Tree');
        return $self->_set_error('invalid target context')
            unless $target->isin($self);
    }

    my $index;

    if($where eq '-before')
    {
        $index = $target->_get_index;
    }
    elsif($where eq '-after')
    {
        $index = $target->_get_index + 1;
    }
    elsif($where eq '-ontop')
    {
        $index = 0;
    }
    elsif($where eq '-onbottom' || $where eq '')
    {
        $index = -1;
    }
    else
    {
        return $self->_set_error('malformed arguments');
    }

    my $item;

    if(ref $type)
    {
        $item = $type;
        $self->_add_child($item, $index);
    }
    elsif($type eq 'section')
    {
        return $self->_set_error('to few arguments')
            unless(defined $name and defined $value);
        my $raw = $self->write_section($name, $value);
        my $length = () = $raw =~ /\n/g;
        $item = $self->_insert_section($name, $value, $raw, $length, $index);
        $item->{raw2} = $self->write_section_closing($name);
        $item->{length2} = () = $item->{raw2} =~ /\n/g;
    }
    elsif($type eq 'directive')
    {
        return $self->_set_error('to few arguments')
            unless(defined $name);
        my $raw = $self->write_directive($name, $value);
        my $length = () = $raw =~ /\n/g;
        $item = $self->_insert_directive($name, $value, $raw, $length, $index);
    }
    elsif($type eq 'comment')
    {
        # $name contents value here
        return $self->_set_error('to few arguments')
            unless(defined $name);
        my $group = defined $value && $value ? 1 : 0;
        $item = $self->_insert_comment($name,
                    $self->write_comment($name), $index, $group);
    }
    elsif($type eq 'blank')
    {
        # enabled by default
        my $group = defined $name ? ($name ? 1 : 0) : 1;
        $item = $self->_insert_blank($self->write_blank(1), $index, $group);
    }
    else
    {
        return $self->_set_error("invalid type `$type'");
    }

    return $item;
}

=pod

=head2 add_section

    $section = $obj->add_section($name, $value)

Same as calling add('section', $name, $value)

=cut

sub add_section
{
    my $self = shift;
    return $self->add('section', @_);
}

=pod

=head2 add_directive

    $directive = $obj->add_directive($name, $value)

Same as calling add('directive', $name, $value)

=cut

sub add_directive
{
    my $self = shift;
    return $self->add('directive', @_);
}

=pod

=head2 add_comment

    $comment = $obj->add_comment("string", [$group])

Same as calling add('comment', 'string', )

$group is a boolean value that control grouping of consecutive comment
lines. Disabled by default.

=cut

sub add_comment
{
    my $self = shift;
    return $self->add('comment', @_);
}

=pod

=head2 add_blank

    $blank = $obj->add_blank([$group])

Same as calling add('blank')

$group is a boolean value that control grouping of consecutive blank
lines. Enabled by default.

=cut

sub add_blank
{
    my $self = shift;
    return $self->add('blank', @_);
}


=pod

=head2 set_value

    $obj->set_value($newvalue)

Change the value of a directive or section. If no argument given,
return the value.

=head2 value

Returns the value of item pointed by the object if any.

(Actually C<value> and C<set_value> are the same method)

=cut

*set_value = \&value;

sub value
{
    my $self     = shift;
    my $newvalue = shift || return $self->{value};

    my $type     = $self->{type};
    
    if($type eq 'directive' or $type eq 'section')
    {
        # keep indentation
        (my $indent = $self->{raw}) =~ s/^(\s*).*$/$1/s;
        if($newvalue =~ /\n/)
        {
            # new value is multilines
            # write the raw version
            $self->{raw} = sprintf
            (
                $indent . ($type eq 'directive' ? '%s %s' : '<%s %s>')."\n",
                $self->{name},
                join(" \\\n", split(/\n/, $newvalue)),
            );
            # clean it
            $self->{value} = join(' ', map {s/^\s*|\s*$//g; $_} split(/\n/, $newvalue));
            # count lines
            $self->{length} = 1 + $newvalue =~ s/\n//g;
        }
        else
        {
            if($type eq 'directive')
            {
                $self->{raw} = "$indent$self->{name} $newvalue\n";
            }
            else
            {
                $self->{raw} = "$indent<$self->{name} $newvalue>\n";
            }
            $self->{value} = $newvalue;
            $self->{length} = 1;
        }
    }
    elsif($type eq 'comment')
    {
        $newvalue = join(' ', split(/\n/, $newvalue));
        # keep spaces before and after the sharp comment and the
        # number of sharps used (it's pure cosmetic) and put it on
        # front of the new comment
        $self->{raw} =~ s/^(\s*\#+\s*).*$/$1$newvalue\n/s;
        $self->{value} = $newvalue
    }
    else
    {
        return($self->_set_error('method not allowed'));
    }

    return($newvalue);
}

=pod

=head2 move

    $obj->move
    (
        $dest_section,
        -before => target |
        -after => $target |
        '-ontop' |
        '-onbottom'
    )

Move item into given section. See C<add()> method for options
description.

=cut

sub move
{
    my $self = shift;
    my $dest = shift;
    return $self->_set_error("cannot move this section in a subsection of itself")
      if($dest->isin($self, '-recursif'));
    $self->unlink();
    $dest->add($self, @_);
    return;
}

=pod

=head2 copy

    $item->copy
    (
        $dest_section,
        -before => target |
        -after => $target |
        '-ontop' |
        '-onbottom'
    )

Copy item into given section. See C<add()> method for options
description.

=cut

sub copy
{
    my $self = shift;
    my $dest = shift;
    # clone item
    my $clone = $self->clone();
    # insert into destination
    return $dest->add($clone, @_);
}

=pod

=head2 clone

  $clone = $item->clone();

Clone item and all its children. Returns the cloned item.

=cut

sub clone
{
    my($self) = @_;

    my $clone = bless({});
    foreach(keys %$self)
    {
        next if $_ eq 'parent';
        $clone->{$_} = $self->{$_};
    }

    if($self->type() eq 'section')
    {
        # initialize children list
        $clone->{children} = [];
        # clone each children
        foreach($self->select())
        {
            $clone->_add_child($_->clone());
        }
    }

    return $clone;
}

=pod

=head2 first_line

=cut

sub first_line
{
    my($self) = @_;
    return 1 unless $self->parent;
    return ($self->top->_count_lines($self))[0];
}

=pod

=head2 last_line

=cut

sub last_line
{
    my($self) = @_;
    return ($self->top->_count_lines($self))[0]
      unless $self->parent;
    return ($self->top->_count_lines_last($self))[0];
}

=pod

=head2 count_lines

=cut

sub count_lines
{
    my($self) = @_;
    if($self->type eq 'section')
    {
        return $self->last_line - $self->first_line + 1;
    }
    else
    {
        return $self->{length};
    }
}

=pod

=head2 isin

    $boolean = $obj->($section_obj, ['-recursif'])

Returns true if object point to a rule that is in the section
represented by $section_obj. If C<-recursif> option is present, true
is also return if object is a sub-section of target.

    <section target>
        <sub section>
            directive test
        </sub>
    </section>

    $test_directive->isin($target_section)              => return false
    $test_directive->isin($sub_section)                 => return true
    $test_directive->isin($target_section, '-recursif') => return true
    $target_section->isin($target_section)              => return true

=cut

sub isin
{
    my $self     = shift;
    my $recursif = _get_arg(\@_, '-recursif!');
    my $target   = shift || return $self->_set_error('too few arguments');
    $target = $target->{tree} if ref $target eq 'Apache::Admin::Config';
    return 0 unless(defined $self->{parent});
    return($self->_set_error('target is not an object of myself'))
        unless(ref $target && $target->isa('Apache::Admin::Config::Tree'));
    return($self->_set_error('wrong type for target'))
        unless($target->{type} eq 'section');
    return 1 if overload::StrVal($self) eq overload::StrVal($target);

    if($recursif)
    {
        my $parent = $self->{parent};
        while(overload::StrVal($parent) ne overload::StrVal($target))
        {
            $parent = $parent->{parent} || return 0;
        }
        return 1;
    }
    else
    {
        return(overload::StrVal($self->{parent}) eq overload::StrVal($target))
    }
}

sub to_string
{
    my($self, $other, $inv, $meth) = @_;

    if($meth eq 'eq')
    {
        if($^W and (!defined $other or !defined $self->{value}))
        {
            carp "Use of uninitialized value in string eq";
        }
        local $^W;
        return($other eq $self->{value});
    }
    elsif($meth eq 'ne')
    {
        if($^W and (!defined $other or !defined $self->{value}))
        {
            carp "Use of uninitialized value in string ne";
        }
        local $^W;
        return($other ne $self->{value});
    }
    elsif($meth eq '==')
    {
        if($^W and (!defined $other or !defined $self->{value}))
        {
            carp "Use of uninitialized value in numeric eq (==)";
        }
        local $^W;
        return($other == $self->{value});
    }
    elsif($meth eq '!=')
    {
        if($^W and (!defined $other or !defined $self->{value}))
        {
            carp "Use of uninitialized value in numeric ne (!=)";
        }
        local $^W;
        return($other != $self->{value});
    }
    elsif(!defined $self->{value})
    {
        return overload::StrVal($self);
    }
    else
    {
        return $self->{value};
    }
}


=pod

=head2 name

Returns the name of the current pointed object if any

=head2 parent

Returns the parent context of object. This method on the top level
object returns C<undef>.

=head2 type

Returns the type of object.

=cut

sub name
{
    return $_[0]->{name};
}
sub parent
{
    return $_[0]->{parent};
}
sub top
{
    my $top = shift;
    while(defined $top->parent())
    {
        $top = $top->parent();
    }
    return $top;
}
sub type
{
    return $_[0]->{type};
}

=pod

=head2 remove

Synonym for unlink (deprecated). See B<unlink()>.

=head2 unlink

  $boolean = $item->unlink();

Unlinks item from the tree, resulting in two separate trees. The item
to unlink becomes the root of a new tree. 

=cut

*remove = \&unlink;

sub unlink
{
    my($self) = @_;

    if(defined $self->{parent})
    {
        my $index = $self->_get_index;
        if(defined $index)
        {
            splice(@{$self->{parent}->{children}}, $index, 1);
        }
    }

    return 1;
}

=pod

=head2 destroy

  $boolean = $item->destroy();

Destroy item and its children. Caution, you should call delete()
method instead if you want destroy a part of a tree. This method don't
notice item's parents of its death.

=cut

sub destroy
{
    my($self) = @_;
    delete $self->{parent};
    foreach(@{$self->{children}})
    {
        $_->destroy;
    }
    return 1;
}

=pod

=head2 delete

    $booleen = $item->delete;

Remove the current item from it's parent children list and destroy it
and all its children (remove() + destroy()).

=cut

sub delete
{
    my($self) = @_;
    return $self->unlink() && $self->destroy();
}

=pod

=head2 error

Return the last appended error.

=cut

sub error
{
    return $_[0]->top()->{__last_error__};
}

#
# Private methods
#

sub _get_var
{
    my($self, $name) = @_;

    my $value = $self->{$name};
    until(defined $value)
    {
        $self = $self->parent() or last;
    }

    return $value;
}

sub _get_index
{
    my($self) = @_;
    return unless defined $self->{parent}; # if called by top node
    my @pchildren = @{$self->{parent}->{children}};
    for(my $i = 0; $i < @pchildren; $i++)
    {
        return $i if overload::StrVal($pchildren[$i]) eq overload::StrVal($self);
    }
}

sub _deploy
{
    join '',
    map
    {
        if($_->{type} eq 'section')
        {
            ($_->{raw}, _deploy($_), $_->{raw2});
        }
        else
        {
            $_->{raw};
        }
    } @{$_[0]->{children}};
}

sub _count_lines
{
    my $c = $_[0]->{'length'} || 0;
    foreach my $i (@{$_[0]->{children}})
    {
        return($c+1, 1) if(overload::StrVal($_[1]) eq overload::StrVal($i));
        my($rv, $found) = $i->_count_lines($_[1]);
        $c += $rv;
        return($c, 1) if defined $found;
    }
    return $c + (defined $_[0]->{length2} ? $_[0]->{length2} : 0);
}

sub _count_lines_last
{
    my $c = $_[0]->{'length'};
    foreach my $i (@{$_[0]->{children}})
    {
        $c += ($i->_count_lines($_[1]))[0];
        return $c if($_[1] eq $i);
    }
    return $c + $_[0]->{length2};
}

sub _add_child
{
    my($self, $item, $index) = @_;

    $item->{parent} = $self;
    if(defined $index && $index != -1)
    {
        splice(@{$self->{children}}, $index, 0, $item);
    }
    else
    {
        push(@{$self->{children}}, $item);
    }
}

sub _insert_directive
{
    my($tree, $directive_name, $value, $line, $length, $index) = @_;

    $value = defined $value ? $value : '';
    $value =~ s/^\s+|\s+$//g;

    my $directive = bless({});
    $directive->{type} = 'directive';
    $directive->{name} = $directive_name;
    $directive->{value} = $value;
    $directive->{raw} = $line;
    $directive->{'length'} = $length;

    $tree->_add_child($directive, $index);

    return $directive;
}

sub _insert_section
{
    my($tree, $section_name, $value, $line, $length, $index) = @_;

    $value = defined $value ? $value : '';
    $value =~ s/^\s+|\s+$//g;

    my $section = bless({});
    $section->{type} = 'section';
    $section->{name} = $section_name;
    $section->{value} = $value;
    $section->{children} = [];
    $section->{raw} = $line;
    $section->{'length'} = $length;

    $tree->_add_child($section, $index);

    return $section;
}

sub _insert_comment
{
    my($tree, $value, $line, $index, $group) = @_;

    my $comment = bless({});

    # if last item is a comment, group next comment with it to make
    # multi-line comment instead of several single-line comment items
    my $_index = defined $index ? $index : -1;
    if(defined $group && $group
       && defined $tree->{children}->[$_index]
       && $tree->{children}->[$_index]->type eq 'comment')
    {
        $comment = $tree->{children}->[$_index];
        $value = "\n$value";
    }
    else
    {
        $comment->{type} = 'comment';
        $tree->_add_child($comment, $index);
    }

    $comment->{value} .= $value;
    $comment->{raw} .= $line;
    $comment->{'length'}++;

    return $comment;
}

sub _insert_blank
{
    my($tree, $line, $index, $group) = @_;

    my $blank = bless({});

    # if last item is a blank line, group next blank line with it to
    # make multi-line blank item instead of several single-line blank
    # items
    my $_index = defined $index ? $index : -1;
    if(defined $group && $group
       && defined $tree->{children}->[$_index]
       && $tree->{children}->[$_index]->type eq 'blank')
    {
        $blank = $tree->{children}->[$_index];
    }
    else
    {
        $blank->{type} = 'blank';
        $tree->_add_child($blank, $index);
    }

    $blank->{raw} .= $line;
    $blank->{'length'}++;

    return $blank;
}

sub _parse
{
    my($self, $fh) = @_;
    my $file = $self->{htaccess} || '[inline]';

    my $cgroup = $self->{'comment-grouping'};
    my $bgroup = $self->{'blank-grouping'};
    # level is used to stock reference to the curent level, level[0] is the root level
    my @level = ($self);
    my($line, $raw_line);
    my $n = 0;
    while((defined $fh) && ($line = scalar <$fh>) && (defined $line))
    {
        $n++;
        my $length = 1;
        $raw_line = $line;

        while($line !~ /^\s*#/ && $line =~ s/\\$//)
        {
            # line is truncated, we want the entire line
            $n++;
            $length++;
            chomp($line);
            my $next .= <$fh> 
                or return $self->_set_error(sprintf('%s: syntax error at line %d', $file, $n));
            $raw_line .= $next;
            $next =~ s/^\s*|\s*$//g;
            $line .= $next;
        }

        $line =~ s/^\s*|\s*$//g;

        if($line =~ /^\s*#\s?(.*?)\s*$/)
        {
            # it's a comment
            _insert_comment($level[-1], $1, $raw_line, undef, $cgroup);
        }
        elsif($line eq '')
        {
            # it's a blank line
            _insert_blank($level[-1], $raw_line, undef, $bgroup);
        }
        elsif($line =~ /^(\w+)(?:\s+(.*?)|)$/)
        {
            # it's a directive
            _insert_directive($level[-1], $1, $2, $raw_line, $length);
        }
        elsif($line =~ /^<\s*(\w+)(?:\s+([^>]+)|\s*)>$/)
        {
            # it's a section opening
            my $section = _insert_section($level[-1], $1, $2, $raw_line, $length);
            push(@level, $section);
        }
        elsif($line =~ /^<\/\s*(\w+)\s*>$/)
        {
            # it's a section closing
            my $section_name = lc $1;
            return $self->_set_error(sprintf('%s: syntax error at line %d', $file, $n)) 
              if(!@level || $section_name ne lc($level[-1]->{name}));
            $level[-1]->{raw2} = $raw_line;
            $level[-1]->{length2} = $length;
            pop(@level);
        }
        else
        {
            return $self->_set_error(sprintf('%s: syntax error at line %d', $file, $n));
        }
    }

    eval('use Data::Dumper; print Data::Dumper::Dumper($self), "\n";') if($Apache::Admin::Config::DEBUG);

    return 1;
}

sub _get_arg
{
    my($args, $motif) = @_;
    # motif is a list of searched argument separated by a pipe
    # each arguments can be ended by a ! for specifing that it don't wait for a value
    # (ex: "-arg1|-arg2!" here -arg2 is boolean)
    # return (value, argname)

    return '' unless(@$args);
    for(my $n = 0; $n < @$args; $n++)
    {
        foreach my $name (split(/\|/, $motif))
        {
            my $boolean = ($name =~ s/\!$//);
            if(defined $args->[$n] && !ref($args->[$n]) && $args->[$n] eq $name)
            {
                return(undef) if(!$boolean && $n+1 >= @$args); # malformed argument
                my $value = splice(@$args, $n, ($boolean?1:2));
                $value = '' unless defined $value;
                return(wantarray ? ($value, $name) : $value); # suppres argument name and its value from the arglist and return the value
            }
        }
    }
    return '';
}

sub _init
{
    my $self = shift;
    return $self->_parse;
}

sub _load
{
    my($self, $htaccess) = @_;
    my @htaccess;
    my $fh;

    $self->{htaccess} = $htaccess;

    if(ref $htaccess eq 'GLOB')
    {
        $fh = $htaccess;
    }
    else
    {
        # just return true if file doesn't exist and -create was enabled
        return 1 if(not -f $htaccess and $self->{create});
        
        return $self->_set_error("`$htaccess' not readable") unless(-r $htaccess);
        $fh = new FileHandle($htaccess) or return $self->_set_error("can't open `$htaccess' file for reading");
    }
    
    return $self->_parse($fh);
}

sub _set_error
{
    my $self = shift;
    $Apache::Admin::Config::ERROR = $self->top->{__last_error__} = join('', (caller())[0].': ', @_);
    return;
}

1;

=pod

=head1 EXAMPLES

  #
  # Reindent configuration file properly
  #

  my $conf = Apache::Admin::Config
    (
     '/etc/apache/httpd.conf',
     -indent => 2
    );

  $conf->save('-reformat');

  #
  # Managing virtual-hosts:
  #

  my $conf = new Apache::Admin::Config "/etc/apache/httpd.conf";

  # adding a new virtual-host:
  my $vhost = $conf->add_section(VirtualHost=>'127.0.0.1');
  $vhost->add_directive(ServerAdmin=>'webmaster@localhost.localdomain');
  $vhost->add_directive(DocumentRoot=>'/usr/share/www');
  $vhost->add_directive(ServerName=>'www.localhost.localdomain');
  $vhost->add_directive(ErrorLog=>'/var/log/apache/www-error.log');
  my $location = $vhost->add_section(Location=>'/admin');
  $location->add_directive(AuthType=>'basic');
  $location->add_directive(Require=>'group admin');
  $conf->save;

  # selecting a virtual-host:
  my $vhost;
  foreach my $vh (@{$conf->section('VirtualHost')})
  {
      if($vh->directive('ServerName')->value eq 'www.localhost.localdomain')
      {
          $vhost = $vh;
          last;
      }
  }

  #
  # Suppress all comments in the file
  # 

  sub delete_comments
  {
      foreach(shift->comment)
      {
          $_->delete;
      }
  }

  sub delete_all_comments
  {
      foreach($_[0]->section)
      {
          delete_all_comments($_);
      }
      delete_comments($_[0]);
  }

  delete_all_comments($conf);

  #
  # Transform configuration file into XML format
  #

  my $c = new Apache::Admin::Config "/path/to/file", -indent => 2
    or die $Apache::Admin::Config::ERROR;

  $c->set_write_directive(sub {
      my($self, $name, $value) = @_;
      return($self->indent.qq(<directive name="$name" value="$value />\n));
  });
  $c->set_write_section(sub {
      my($self, $name, $value) = @_;
      return($self->indent.qq(<section name="$name" value="$value">\n));
  });
  $c->set_write_section_closing(sub {
      my($self, $name) = @_;
      return($self->indent."</section>\n");
  });
  $c->set_write_comment(sub {
      my($self, $value) = @_;
      $value =~ s/\n//g;
      return($self->indent."<!-- $value -->");
  });
  print $c->dump_reformat();


=head1 AUTHOR

Olivier Poitrey E<lt>rs@rhapsodyk.netE<gt>

=head1 AVAILABILITY

The official FTP location is:

B<ftp://ftp.rhapsodyk.net/pub/devel/perl/Apache-Admin-Config-current.tar.gz>

Also available on CPAN.

anonymous CVS repository:

CVS_RSH=ssh cvs -d anonymous@cvs.rhapsodyk.net:/devel co Apache-Admin-Config

(supply an empty string as password)

CVS repository on the web:

http://www.rhapsodyk.net/cgi-bin/cvsweb/Apache-Admin-Config/

=head1 BUGS

Please send bug-reports to aac@list.rhapsodyk.net. You can subscribe to the list
by sending an empty mail to aac-subscribe@list.rhapsodyk.net.

=head1 LICENCE

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

=head1 COPYRIGHT

Copyright (C) 2001 - Olivier Poitrey
