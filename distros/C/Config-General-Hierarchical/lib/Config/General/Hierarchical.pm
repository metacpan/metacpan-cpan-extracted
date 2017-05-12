#
# Config::General::Hierarchical.pm - Hierarchical Generic Config Module
#
# Purpose: Permits to organize configuration values
#          in a hierarchical structure of files
#
# Copyright (c) 2007-2009 Daniele Ricci <icc |AT| cpan.org>.
# All Rights Reserved. Std. disclaimer applies.
# Artificial License, same as perl itself.

package Config::General::Hierarchical;

$Config::General::Hierarchical::VERSION = 0.07;

use strict;
use warnings;

use Carp;
use Clone::PP qw( clone );
use Config::General;
use Config::General::Hierarchical::ExcludeWeaken;
use Cwd qw( abs_path );
use Scalar::Util qw( weaken );

use base 'Class::Accessor::Fast';

my @properties = qw( constraint name opt value );
my %properties = map( ( $_ => 1 ), @properties );

__PACKAGE__->mk_accessors( @properties, qw( cache ) );

my %Config_General_Proxy = (
    '-AutoLaunder'    => 1,
    '-CComments'      => 1,
    '-LowerCaseNames' => 1,
    '-SplitDelimiter' => 1,
    '-SplitPolicy'    => 1,
);

sub new {
    my ( $ref, %args ) = @_;

    my $file;
    my %general;
    my %props;
    my %options;

    foreach my $key ( keys %args ) {
        if ( $key eq 'file' ) {
            $file = $args{$key};
        }
        elsif ( $properties{$key} ) {
            $props{$key} = $args{$key};
        }
        elsif ( $Config::General::Hierarchical::Options::options{$key} ) {
            $options{$key} = $args{$key};
        }
        elsif ( $Config_General_Proxy{$key} ) {
            $general{$key} = $args{$key};
        }
    }

    my $class = ref $ref || $ref or croak __PACKAGE__ . ": wrong new call";
    my $self = $class->SUPER::new(
        {
            cache => {},
            %props
        }
    );

    unless (%props) {
        $self->opt(
            Config::General::Hierarchical::Options->new(
                {
                    files     => [],
                    general   => \%general,
                    inherits  => 'inherits',
                    root      => $self,
                    struct    => { '0' => {} },
                    undefined => 'undefined',
                    wild      => '*',
                    %options
                }
            )
        );

        weaken( $self->opt->{root} )
          unless $Config::General::Hierarchical::ExcludeWeaken::exclude;

        $self->read($file) if $file;

        $self->check if $args{check};
    }

    return $self;
}

sub check {
    my ($self) = @_;

    foreach my $key ( keys %{ $self->value } ) {
        my $v = $self->get($key);

        $v->check if eval { $v->isa(__PACKAGE__); };
    }

    return $self;
}

sub import {
    my ( $class, @pars ) = @_;
    my $syntax = $class->syntax;

    die "$class: syntax method musts return an HASH reference\n"
      if ref $syntax ne 'HASH';

    $class->check_syntax( $syntax, [] );
}

sub check_syntax {
    my ( $class, $syntax, $parents ) = @_;

    foreach my $key ( keys %$syntax ) {
        my $ref = ref $syntax->{$key};
        my $syn = $syntax->{$key};

        push @$parents, $key;

        if ($ref) {
            die "$class: wrong use of $ref reference as syntax for variable '"
              . join( '->', @$parents ) . "'\n"
              if $ref ne 'HASH';

            $class->check_syntax( $syn, $parents );
        }
        else {
            die "$class: wrong '$syn' syntax for variable '"
              . join( '->', @$parents ) . "'\n"
              if defined $syn && $syn !~ /^[amuABDEINST]*$/;

            die
"$class: wrong use of 'm' flag for not string nor array variable '"
              . join( '->', @$parents ) . "'\n"
              if defined $syn
                  && $syn =~ /m/
                  && syntax_check_get_type($syn) ne 'S'
                  && $syn !~ /a/;
        }

        pop @$parents;
    }
}

sub get {
    my ( $self, $name, @names ) = @_;

    my $vname = $self->name ? $self->name . '->' . $name : $name;

    if ( exists $self->cache->{$name} ) {
        my $value = $self->cache->{$name};

        return $value unless scalar @names;
        return $value->get(@names) if eval { $value->isa(__PACKAGE__) };

        croak __PACKAGE__
          . ": can't get subkey '$names[0]' value for not node variable '$vname'";
    }

    my $syntax =
      exists $self->constraint->{$name}
      ? $self->constraint->{$name}
      : $self->constraint->{ $self->wild };
    my $value = $self->value->{$name} || $self->value->{ $self->wild };

    if ( !defined $value || ref $value->value ne 'HASH' ) {
        croak __PACKAGE__
          . ": can't get subkey '$names[0]' value for not node variable '$vname'"
          if scalar @names;

        return $self->cache->{$name} =
          $self->syntax_check( $vname, $value, $syntax );
    }

    $self->cache->{$name} = $value = $self->syntax_check(
        $vname,
        $self->new(
            constraint => $syntax || {},
            name       => $vname,
            opt        => $self->opt,
            value      => $value->value
        ),
        $syntax
    );

    return $value unless scalar @names;

    return $value->get(@names);
}

our $AUTOLOAD;

sub AUTOLOAD {
    my ( $self, @args ) = @_;
    my $name = $AUTOLOAD;

    $name =~ s/\w+:://g;

    return $self->get( $1, @args ) if $name =~ /^_(\w+)$/;

    return $self->opt->$name
      if $Config::General::Hierarchical::Options::options{$name};

    my $ref = ref $self;

    croak "Can't locate object method \"$name\" via package \"$ref\"";
}

# simply avoid AUTOLOAD is called when an object is destroied
sub DESTROY { }

sub getk {
    my ($self) = @_;

    croak __PACKAGE__ . ": can't get keys before reading any file"
      unless $self->value;

    return keys %{ $self->value };
}

sub read {
    my ( $self, $name ) = @_;

    $self->constraint( $self->syntax );
    $self->value( $self->read_( $name, [] ) );
    $self->expand_wild_keys( $self->value );
    $self->name('');

    return $self;
}

sub read_ {
    my ( $self, $name, $children ) = @_;

    my $tmp = eval { abs_path($name); };
    my $error = $@ || !$tmp;
    $name = $tmp if $tmp;
    my $files = $self->opt->files;
    my $in_file =
        $name
      . join( '', reverse( map( "\ninherited by: $files->[$_]", @$children ) ) )
      . "\n ";
    my $nfile = scalar @$files;

    croak __PACKAGE__ . ": no such directory: $in_file" if $error;
    croak __PACKAGE__ . ": no such file: $in_file" unless -e $name;
    croak __PACKAGE__ . ": recursive hierarchy\nin file: $in_file"
      if grep /^$name$/, map $files->[$_], @$children;
    push @$files, $name;

    my $cfg;
    eval {
        $cfg = Config::General->new(
            '-AllowMultiOptions'     => 1,
            '-AutoTrue'              => 0,
            '-CComments'             => 0,
            '-ConfigFile'            => $name,
            '-ExtendedAccess'        => 0,
            '-InterPolateEnv'        => 0,
            '-InterPolateVars'       => 0,
            '-MergeDuplicateBlocks'  => 1,
            '-MergeDuplicateOptions' => 0,
            '-SlashIsDirectory'      => 0,
            '-UseApacheInclude'      => 0,
            ( %{ $self->opt->general } )
        );
    };

    if ($@) {
        my @list = split /\n/, $@;
        pop @list;
        my $msg = join "\n", @list;

        croak __PACKAGE__ . ": $msg\nin file: $in_file";
    }

    if ( scalar @$children ) {
        my $str = $self->opt->struct;

        foreach (@$children) {
            $str = $str->{$_};
        }

        $str->{$nfile} = {};
    }

    my $hash     = { $cfg->getall };
    my $syntax   = $self->inherits;
    my $inherits = $hash->{$syntax};

    delete $hash->{$syntax};
    my ( $undefined, $value ) = $self->convert_hash( $hash, $nfile, $in_file );

    if ($inherits) {
        my $parents;

        if ( !ref $inherits ) {
            $parents = [$inherits];
        }
        elsif ( ref $inherits eq 'ARRAY' ) {
            $parents = $inherits;
        }
        else {
            croak __PACKAGE__
              . ": wrong use of inherits ('$syntax') directive\nin file: $in_file";
        }

        push @$children, @$files - 1;
        foreach my $parent ( reverse @$parents ) {
            if ( $parent =~ /^\// ) {
                $name = $parent;
            }
            else {
                my @list = split /\//, $name;
                pop @list;
                $name = join( '/', @list ) . '/' . $parent;
            }

            $hash = $self->read_( $name, $children );

            $self->merge_values( $value, $hash, $self->constraint );
        }
        pop @$children;
    }

    $self->undefine( $value, $undefined, $nfile );

    return $value;
}

sub convert_hash {
    my ( $self, $hash, $file, $in_file ) = @_;

    my $syntax = $self->inherits;
    my %undefined;

    croak __PACKAGE__
      . ": inherits ('$syntax') directive cannot be used as node name\nin file: $in_file"
      if exists $hash->{$syntax};

    $syntax = $self->undefined;
    my $undefined = $hash->{$syntax};
    delete $hash->{$syntax};

    foreach my $key ( keys %$hash ) {
        if ( ref $hash->{$key} eq 'HASH' ) {
            ( $undefined{$key}, my $tmp ) =
              $self->convert_hash( $hash->{$key}, $file, $in_file );
        }
        $hash->{$key} = '' unless defined $hash->{$key};
        $hash->{$key} = Config::General::Hierarchical::Value->new(
            { value => $hash->{$key}, file => $file } );
    }

    if ($undefined) {
        if ( !ref $undefined ) {
            $undefined{$undefined} = undef;
        }
        elsif ( ref $undefined eq 'ARRAY' ) {
            $undefined{$_} = undef foreach @$undefined;
        }
        else {
            croak __PACKAGE__
              . ": wrong use of undefined ('$syntax') directive\nin file: $in_file";
        }
    }

    return ( \%undefined, $hash );
}

sub merge_values {
    my ( $self, $value, $hash, $constraint ) = @_;
    my ( $key, $val );

    foreach $key ( keys %$value ) {
        $val = $value->{$key};

        if ( ref $val eq 'Config::General::Hierarchical::Value' ) {
            my $other = exists $hash->{$key} ? $hash->{$key}->value : undef;
            my $syn = (
                exists $constraint->{$key}
                ? $constraint->{$key}
                : $constraint->{ $self->wild }
              )
              || {};

            if ( ref $val->value eq 'HASH' ) {
                if ( ref $other eq 'HASH' ) {
                    $self->merge_values( $val->value, $other, $syn );
                }
            }
            elsif ( !ref $syn && $syn =~ /m/ && defined $other ) {
                if ( $syn =~ /a/ ) {
                    $other = [$other] unless ref $other;

                    if ( ref $val->value ) {
                        unshift @{ $val->value }, @$other;
                    }
                    else {
                        $val->value( [ @$other, $val->value ] );
                    }
                }
                else {
                    $val->value( $other . $val->value );
                }
            }
        }
        elsif ( ref $val eq 'HASH' ) {
            if ( exists $hash->{$key} && ref $hash->{$key} eq 'HASH' ) {
                $self->merge_values( $val, $hash->{$key} );
            }
        }
    }

    foreach $key ( keys %$hash ) {
        $value->{$key} = $hash->{$key} unless exists $value->{$key};
    }

    return $value;
}

sub expand_wild_keys {
    my ( $self, $value ) = @_;

    my $wild = $self->wild;
    my $wv   = $value->{$wild};

    if ( $wv && ref $wv->value eq 'HASH' ) {
        $wv = $wv->value;

        foreach my $key ( keys %$value ) {
            my $v = $value->{$key}->value;

            next if $key eq $wild;
            next if ref $v ne 'HASH';

            foreach my $wk ( keys %$wv ) {
                $v->{$wk} = clone( $wv->{$wk} ) unless exists $v->{$wk};
            }
        }
    }

    foreach my $key ( keys %$value ) {
        my $v = $value->{$key}->value;

        next if $key eq $wild;
        next if ref $v ne 'HASH';

        $self->expand_wild_keys($v);
    }
}

sub undefine {
    my ( $self, $value, $undefined, $file ) = @_;

    foreach my $key ( keys %$value ) {
        next unless exists $undefined->{$key};

        if ( defined $undefined->{$key} ) {
            $self->undefine( $value->{$key}->value, $undefined->{$key}, $file );
        }
        else {
            $value->{$key} = Config::General::Hierarchical::Value->new(
                { value => undef, file => $file } );
        }
    }
}

sub syntax {
    return {};
}

my %types = (
    A => { d => 'datetime',       e => '^\d\d\d\d-\d\d-\d\d \d\d:\d\d:\d\d$' },
    B => { d => 'boolean value',  e => '^(0|1|on|off|yes|no|true|false)$' },
    D => { d => 'date',           e => '^\d\d\d\d-\d\d-\d\d$' },
    E => { d => 'e-mail address', e => '^[\w\d\-_\.]+@[\w\d\-_\.]+\.\w+$' },
    I => { d => 'integer value',  e => '^-?\d+$' },
    N => { d => 'number',         e => '^-?\d*\.?\d+$' },
    S => { d => 'string' },
    T => { d => 'time',           e => '^\d\d:\d\d:\d\d$' },
);

sub syntax_check {
    my ( $self, $vname, $value, $syntax ) = @_;
    my $can_be_undefined;
    my $file = 0;

    if ( defined $value
        && ref $value eq 'Config::General::Hierarchical::Value' )
    {
        $file  = $value->file;
        $value = $value->value;
    }
    $file = "\nin file: " . $self->opt->files->[$file];

    if ( defined $syntax ) {
        $can_be_undefined =
          ref $syntax ? exists $syntax->{ $self->undefined } : $syntax =~ /u/;
    }
    elsif ( defined $value ) {
        return ref $value ? $value : $self->convert_value( $value, $vname )
          if ref $value ne 'ARRAY';

        croak __PACKAGE__
          . ": variable '$vname' is an array: should be a string or a node$file";
    }

    unless ( defined $value ) {
        if ($can_be_undefined) {
            return undef if ref $syntax;
            return [] if $syntax =~ /a/;
            return 0 if $syntax =~ /B/;
            return undef;
        }

        croak __PACKAGE__ . ": request for undefined variable '$vname'$file";
    }

    if ( ref $syntax ) {
        return $value if eval { $value->isa(__PACKAGE__) };

        croak __PACKAGE__ . ": variable '$vname' should be a node$file";
    }

    my $type = syntax_check_get_type($syntax);

    if ( $syntax !~ /a/ ) {
        croak __PACKAGE__
          . ": variable '$vname' is an array but should be a $types{$type}->{d}$file"
          if ref $value eq 'ARRAY';    #"}"
        croak __PACKAGE__
          . ": variable '$vname' is a node but should be a $types{$type}->{d}$file"
          if ref $value;               #"}"

        $value = $self->convert_value( $value, $vname );

        return $value if $type eq 'S';

        $value =~ s/^\s+//;
        $value =~ s/\s+$//;

        croak __PACKAGE__
          . ": value '$value' for variable '$vname' is not a prooper $types{$type}->{d}$file"
          unless $value =~ /$types{$type}->{e}/i;    #}"}"

        return $value if $type ne 'B';
        return $value =~ /(1|on|yes|true)/i ? 1 : 0;
    }

    my $ref = ref $value;
    my @ret;
    my $arr = $ref ? $value : [$value];

    croak __PACKAGE__ . ": variable '$vname' should be an array$file"
      if $ref && $ref ne 'ARRAY';

    if ( $type eq 'S' ) {
        @ret = @$arr;
    }
    else {
        foreach $value (@$arr) {
            $value =~ s/^\s+//;
            $value =~ s/\s+$//;

            my @values = split /\s*,\s*/, $value;

            foreach $value (@values) {
                croak __PACKAGE__
                  . ": element '$value' of variable '$vname' is not a prooper $types{$type}->{d}$file"
                  if $value !~ /$types{$type}->{e}/i;    #}"}"

                push @ret, $value;
            }
        }
    }

    return [ map $self->convert_value( $_, $vname ), @ret ];
}

sub syntax_check_get_type {
    my ($syntax) = @_;

    foreach (qw( A B D E I N T )) {
        return $_ if $syntax =~ /$_/;
    }

    return 'S';
}

my %back_slash = (
    36  => 36,
    92  => 92,
    97  => 7,
    98  => 8,
    102 => 12,
    110 => 10,
    114 => 13,
    116 => 9,
    118 => 11,
);

sub convert_value {
    my ( $self, $value, $vname ) = @_;

    my @arr = unpack 'C*', $value;
    my @ret;

    while ( my $c = shift @arr ) {
        if ( $c == 92 && scalar @arr ) {    # \
            my $n = shift @arr;

            if ( $back_slash{$n} ) {
                push @ret, $back_slash{$n};
            }
            else {
                push @ret, 92, $n;
            }
        }
        elsif ( $c == 36 && scalar @arr && $arr[0] == 123 ) {    # $
            my $i;
            my $v;
            my @var_name;

            for ( $i = 1 ; $i < scalar @arr && $arr[$i] != 125 ; ++$i ) {
                push @var_name, $arr[$i];
            }

            croak __PACKAGE__
              . ": systax error in inline variable substitution for value '$value' for variable '$vname'"
              if $i == scalar @arr;
            croak __PACKAGE__
              . ": can't do inline variable substitution for variable '$vname' when reference to root node was lost"
              unless $self->opt->root;

            eval {
                $v = $self->opt->root->get( split /->/, pack 'C*', @var_name );
            };

            croak "$@ during inline variable sostitution for variable '$vname'"
              if $@;
            croak __PACKAGE__
              . ": can't use node or array variable in inline variable sostitution for variable '$vname'"
              if ref $v;

            $v = '' unless defined $v;
            push @ret, unpack 'C*', $v;
            splice @arr, 0, $i + 1;
        }
        else {
            push @ret, $c;
        }
    }

    return pack 'C*', @ret;
}

package Config::General::Hierarchical::Options;

use base 'Class::Accessor::Fast';

my @options = qw( inherits root undefined wild );
our %options = map( ( $_ => 1 ), @options );

__PACKAGE__->mk_accessors( @options, qw( files general struct ) );

package Config::General::Hierarchical::Value;

use base 'Class::Accessor::Fast';

__PACKAGE__->mk_accessors(qw( file value ));

1;

__END__

=head1 NAME

Config::General::Hierarchical - Hierarchical Generic Config Module

=head1 SYNOPSIS

Simple use

 use Config::General::Hierarchical;
 #
 my $cfg = Config::General::Hierarchical->new( file => $filename );
 my $value = $cfg->_ConfigurationVariableName;

Full use

 package MyConfig;
 #
 use base 'Config::General::Hierarchical';
 #
 sub syntax {
  ...
 }

=head1 DESCRIPTION

This module provides easy ways to achieve three goals: to read configuration values that are organized in
complex structures and stored in a hierarchical structure of files, to access them, and to define syntax
and structure constraints.

=head1 HOW CONFIGURATION DATA ARE ORGANIZED

To make the structure constraints easy to be managed, a good way is to force the configuration
structure to a tree of named B<nodes>; each one can be either a B<parent node> or a B<value node>, if a
B<value> can be a string or an array of strings then this structure can be aesily stored in an perl hash
where for each key can be stored a reference to another hash, a reference to an array of scalars or
a scalar.

This configuration example

 <db>
   <*>
     tout 300
   </*>
   <customers>
     host customersdb.${DBServersDomain}
     name customersdb
     user customerslogin
     pass customerspwd
   </customers>
   <products>
     host productsdb.${DBServersDomain}
     name productsdb
     user productslogin
     pass productspwd
     tout 600
   </products>
   <users>
     host usersdb.${DBServersDomain}
     name usersdb
     user userslogin
     pass userspwd
   </users>
 </db>
 DBServersDomain my.domain

is equivalent to this code

 my $cfg = {
     db => {
         customers => {
             host => 'customersdb.my.domain',
             name => 'customersdb',
             user => 'customerslogin',
             pass => 'customerspwd',
             tout => 300,
         },
         products  => {
             host => 'productsdb.my.domain',
             name => 'productsdb',
             user => 'productslogin',
             pass => 'productspwd',
             tout => 600,
         },
         users     => {
             host => 'usersdb.my.domain',
             name => 'usersdb',
             user => 'userslogin',
             pass => 'userspwd',
             tout => 300,
         },
     },
     DBServersDomain => 'my.domain',
 };

=head1 HOW CONFIGURATION FILES ARE READ

For the purpose to read and to parse configuration files L<Config::General> is used, so it is better
if you introduce yourself to that module before going on reading this chapter: it is written assuming
that the reader knows how C<Config::General> reads and parses files.

This is how C<Config::General::Hierarchical> inizializes the C<Config::General> object.

 Config::General->new(
   '-AllowMultiOptions'     => 1,
   '-AutoTrue'              => 0,
   '-BackslashEscape'       => 0,
   '-CComments'             => 0,
   '-ConfigFile'            => $filename,
   '-ExtendedAccess'        => 0,
   '-InterPolateEnv'        => 0,
   '-InterPolateVars'       => 0,
   '-MergeDuplicateBlocks'  => 1,
   '-MergeDuplicateOptions' => 0,
   '-SlashIsDirectory'      => 0,
   '-UseApacheInclude'      => 0,
 );

Inizializing the C<Config::General> module with both the parameters C<-MergeDuplicateBlocks>
and C<-AllowMultiOptions> to true and C<-MergeDuplicateOptions> to false, it reads and parses the file
in a structure respecting the structure constraint. Beeing this module written for configuration file,
neithr C<-ConfigHash> nor C<-String> are used, but C<-ConfigFile> is used for each file to read.
The parameters C<-AutoLaunder>, C<-CComments>, C<-LowerCaseNames>, C<-SplitDelimiter> and
C<-SplitPolicy> are presetted or unsetted, but left at your control: C<new()> methot proxies theese
parameters.

An overview on other L<Config::General> parameters:

=over

=item C<-AutoTrue>

0: this module provides its own way to normalize and check theese values

=item C<-BackslashEscape>

0: this module provides its own way to interpolate backslashes

=item C<-DefaultConfig>

not used: I think this is not a usefull option for the purpose to read more than one file

=item C<-ExtendedAccess>

0: this module provides its own easy way to access data

=item C<-FlagBits>

not used yet: TODO

=item C<-InterPolateEnv> C<-InterPolateVars>

0: this module provides its own way to interpolate values

=item C<-SlashIsDirectory>

0: we don't need to be compliant with apache

=item C<-Tie>

not used yet: TODO

=item C<-UseApacheInclude>

0: this module provides its own way to I<include> other files: the B<inherits directive>; other
parameters changing the I<include> beheavure of C<Config::General> are simply not used and not
mentioned as well

=back

=head1 SUBROUTINES/METHODS

All theese methods (execpt for the C<new()> one) are for internal use, but having you probably to
write a class that hinerits this one, it can be a good thing if you know how the module works.

=head2 C<new()>

=over

=item synopsis

 $cfg = Config::General::Hierarchical->new( %options );

=item return value

Returns a new constructed C<Config::General::Hierarchical> object.

=item description

Some C<%options> can be specified by and hash.

=over

=item C<-AutoLaunder> C<-CComments> C<-LowerCaseNames> C<-SplitDelimiter> C<-SplitPolicy>

Proxied to C<Config::General>.

=item C<check> 1

This make the C<new()> method to implicitally call the C<check()> method as well.

=item C<file> <string>

This make the C<new()> method to implicitally call the C<read()> method as well.

=item C<inherits> <string>

Redefines the default C<inherits> syntax of the same B<directive>.

=item C<undefined> <string>

Redefines the default C<undefined> syntax of the same B<directive>.

=item C<wild> <string>

It defines the B<wild string>. By default it values C<'*'>. If used as key of any B<node>
(etiher in configuration or in the B<syntax constraint>), the relative value is used as
default value (or syntax) for every key requested for that B<node>.

=back

=back

=head2 C<check()>

=over

=item synopsis

 $cfg->check;

=item return value

If it does not die, returns the node itself.

=item description

This mothod calls the C<get()> method for each key of the node with two effects: if the
method returns, all the variables for that node respect the B<syntax constraint>, all
the values are now cached.

=back

=head2 C<import()>

=over

=item synopsis

 use Config::General::Hierarchical;

=item description

This mothod performs the checks on the correct usage of the B<syntax> method.
This means that if there is an error in the B<syntax constraint> it is notifeied to the
developer at compile time.

=back

=head2 C<get()>

=over

=item synopsis

 my $value = $cfg->get( 'VariableName' );
 # alias
 my $value = $cfg->_VariableName;

 my $value = $cfg->get( 'VariableName', 'SubNode' );
 # alias
 my $value = $cfg->_VariableName->get( 'SubNode' );
 # alias
 my $value = $cfg->_VariableName->_SubNode;

 my $value = $cfg->get( 'VariableName', ... );
 # alias
 my $value = $cfg->_VariableName( ... );

=item return value

Returns the B<value> of the B<configuration variable> C<VariableName>.

=item description

Accessing configuration data by this method you can be sure that the returned value
respects the B<syntax constraint>, if this is not the case, a C<die()> is called and any
value is returned.
You can be sure as well that the returned value has the appropriate type defined by the
B<syntax constraint>, this means that when a B<configuration variable> is defined as a
B<node> getting its value you will obtain a reference to a C<Config::General::Hierarchical>
object, when it is defined as an array you will obtain a reference to an C<ARRAY> (even if
empty), otherwise you will get a scalar.

A quicker to write way to access data is provided with C<AUTOLOAD> mothod: you can I<get>
the B<value> of a B<variable> by calling that method called as the name of the B<variable>
prependend by an underscore.

=back

=head2 C<getk()>

=over

=item synopsis

 my @keys = $cfg->getk;

=item description

This mothod returns the array with all the B<keys> configured in the configuration files for
the B<node>.

=back

=head2 C<read()>

=over

=item synopsis

 $cfg->read( $filename );

=item return value

Returns the C<Config::General::Hierarchical> object itself.

=item description

Reads and parses all the file structure, beginning from C<$filename> and following its
hierarchical structure. It I<dies> on error or if called twice. By this method the
C<Config::General::Hierarchical> object becames a B<node>: the configuration B<root node>,
which is the only one without a name: you can reference it by the object.

=back

=head2 C<syntax()>

=over

=item synopsis

 package MyConfig;
 #
 use base 'Config::General::Hierarchical';
 #
 sub syntax {
   my ( $self ) = @_;
   my %constraint = ( ... );
   return $self->merge_values( \%constraint, $self->SUPER::syntax );
 }

=item return value

It must return the reference to the hash describing the B<syntax constraint>.

=item description

This method is called by C<get()>, C<import()> and C<read()> methods in order to check
the struscture syntax of the red configuration.

=back

=head1 DIRECTIVES

There are some configuration variable which C<Config::General::Hierarchical> handles as
B<directives>. This means that will there be some keywords that will can not be used
neither as B<configuration variable> name nor as B<node> name. Anyway, if you strongly need
to use a configuration variable name which is a B<directive> name, you can redefine the
keyword for each B<directive> by this way:

 # This make the include keyword now be handled as the inherits directive
 my $cfg = Config::General::Hierarchical->new( inherits => 'include' );

The same B<directive> can be used more than once in the same configuration file.

=head2 C<inherits>

It specifies a file to I<inherit>. It take one argument: the name of the file to I<inherit>.
If used twice (or more) undefined configuration variables are inherited from the last file in
order to create a temporary configuration tree which inherits the file specified by previous
C<inherits> directive, an so on...

=head2 C<undefined>

It forces a variable to have an undefined value even if it have some value defined in the
inherited structure.
It can be specified more than once and it can be used as B<key> of a B<node> with the same
purpose.

The C<undefined> B<directive> takes precedence on the value. In the following exaple C<undef>
is returned.

 # configuration
 <node>
  key 1
  undefined key
 </node>

 # code
 $cfg->_node->_key;

=head2 C<wild>

It's default value is C<'*'>. It can be used to specify default value or B<syntax constraint>
for all the other key not specified and requested for the same B<node> where a B<wild key> is
defined.
For example it can be used to specify that every database timeout must be and integer and
that its default value is 300: in the following example both C<< $cfg->_db->_customers->_tout >>
and C<< $cfg->_db->_users->_tout >> will return C<300> while C<< $cfg->_db->_products->_tout >>
will returns C<600> and C<< $cfg->_db->_example->_tout >> will I<die>.

 # configuration
 <db>
   <*>
     tout 300
   </*>
   <customers>
     host customersdb.${DBServersDomain}
     name customersdb
     user customerslogin
     pass customerspwd
   </customers>
   <example>
     tout alphanumeric
   </example>
   <products>
     host productsdb.${DBServersDomain}
     name productsdb
     user productslogin
     pass productspwd
     tout 600
   </products>
   <users>
     host usersdb.${DBServersDomain}
     name usersdb
     user userslogin
     pass userspwd
   </users>
 </db>
 DBServersDomain my.domain

 # code
 package MyConfig;
 #
 use base 'Config::General::Hierarchical';
 #
 sub syntax {
   my ( $self ) = @_;
   my %constraint = ( db => {
     '*' => {
       tout => 'I'
     }
   } );
   return $self->merge_values( \%constraint, $self->SUPER::syntax );
 }

=head1 SYNTAX CONSTRAINT

The B<syntax constraint> specifies the option variable tree and the syntax that variables
must respect. To specify the structure and the syntax this module uses an hash for each
B<node> where each key is the name of a B<configuration variable> and values can be either
a string defining the B<variable syntax> or a reference to an other hash if the
B<configuration variable> is a B<node>. A B<variable syntax> can contains an uppercase
letter to specify the B<type> of the B<configuration variable> and/or some lowercase letter
to specify some B<flags>. I<It is not mandatory to specify every key!> When there is any
specification for a B<configuration variable> requested by B<get> any check is performed if
it is a B<node> otherwise the value must be simply defined.
The B<syntax constraint> is checked when the B<get> method is called: if the B<configuration
variable> doesn't respect the syntax a B<die> is called.

=head2 TYPES

The B<type> is specified by an uppercase letter, if not specified the default is B<string>.

=over

=item datetime

B<A> - a date and time value: 'YYYY-mm-dd HH:MM:SS'

=item boolean

B<B> - a boolean value

=item date

B<D> - a date: 'YYYY-mm-dd'

=item e-mail

B<E> - an e-mail address

=item integer

B<I> - an integer number

=item number

B<N> - a floating point numer

=item string

B<S> - a string even if empty

=item time

B<T> - a time: 'HH:MM:SS'

=back

=head2 FLAGS

The B<flags> are specified by a lowercase letter.

=over

=item array

B<a> - the variable is an array: when the value is getted a reference to an ARRAY is returned

=item merge

B<m> - the hinerited value is merged instead of overwritten; it can be used only for strings
and arrays

=item undefined

B<u> - the value can be undefined

=back

=head2 MULTIPLE FLAGS

There are a few of thing to pay attention when many B<flags> are specified.

=over

=item am

This is the tipical B<m> use.

=item au

A reference to an ARRAY is returned, empty if the value is B<undefined>.

=back

=head1 BACKSLASH ESCAPEING

The B<get> method before performing the B<syntax constraint> check parses the value in order
to escape the backslashes. The following backslasch sequences are recognised.

=over

=item \\ backslash

=item \$ dollar

=item \a beel

=item \b backspace

=item \f form feed

=item \n new line

=item \r carriage return

=item \t horizontal tabulator

=item \v vertical tabulator

=back

A backslash at the end of the line makes the following line to be concatenated with the
current one, this is a L<Config::General> feature. In the following example I<$value>
contains the value 'valuecontinued'.

 # config file
 variable value\
 continued

 #code
 my $value = $cfg->variable;

=head1 INLINE VARIABLE SUBSTITUTION

If a B<value> contains the following syntax

 ${variable_name}

this token is substituted with the B<value> of C<variable_name>. The I<inline variable
substitution> is made at get time, so the B<value> substituted is the final one of the
variable. The B<value> of C<variable_name> is obtained by a C<get()> call, so the B<syntax
constraiant> check is performed on it before the substitution.

To do the I<inline variable substituition> is necessary that a reference to the B<root
node> is still alive, otherwise a C<die()> is called. Anyway, it is possible to call the
C<check()> method on the B<node> before loosing the B<root node> reference in order to
cache all the values. It can be called explicitally on a B<node> of implicitally by
the C<new()> methed using the C<check> parameter with a true value.

 # config.conf file
 <node>
  key ${var}
 </node>
 var value

In the following exaple a C<die()> is called

 my $node = get_node;
 $node->_key; # this generates a die call
 #
 sub get_node {
   my $cfg = Config::General::Hierarchical->new( file => 'config.conf' );
   return $cfg->_node;
 }

This can be prevented by this way

 my $node = get_node;
 $node->_key;
 #
 sub get_node {
   my $cfg = Config::General::Hierarchical->new( file => 'config.conf', check => 1 );
   return $cfg->_node;
 }

or by this way (more efficient than previous).

 my $node = get_node;
 $node->_key;
 #
 sub get_node {
   my $cfg  = Config::General::Hierarchical->new( file => 'config.conf' );
   return $cfg->_node->check;
 }

When an C<undef> variable is requested during I<inline variable substitution>, its value is
substituted with an empty string.

The syntax to access the B<value> of a B<subkey> while in I<inline variable substitution> is
C<< -> >> ; in the following example C<< $cfg->_var >> will return C<'abc'> .

 # configuration
 <node>
  key b
 <node>
 var a${node->key}c

=head1 DUMPING CONFIGURATION

The module L<Config::General::Hierachical::Dump> offers a simple and usefull way to I<dump>
configurration files.

=head1 EXAMPLE

Using many of the features of C<Config::General::Hierarchical> it is possible to do so.

 $ cat MyConfig.pm
 package MyConfig;
 use base 'Config::General::Hierarchical';
 sub syntax {
     my ( $self ) = @_;
     my %constraint = (
         GMTOffsett => 'I',
         IdString   => 'm',
     );
     return $self->merge_values( \%constraint, $self->SUPER::syntax );
 }
 1;

 $ cat MyConfigDump.pm
 package MyConfigDump;
 use base 'Config::General::Hierarchical::Dump';
 use MyConfig;
 sub parser { return 'MyConfig' };
 1;

 $ cat base.conf
 #!/usr/bin/perl -MMyConfigDump
 GMTOffsett N/A
 IdString MyApp
 LogString MyFacility-${IdString}

 $ cat eu.conf
 #!/usr/bin/perl -MMyConfigDump
 inherits base.conf
 GMTOffsett -1
 IdString Eu
 Rate UER

 $ cat fr.conf
 #!/usr/bin/perl -MMyConfigDump
 inherits eu.conf
 IdString Fr

 $ cat gb.conf
 #!/usr/bin/perl -MMyConfigDump
 inherits eu.conf
 GMTOffsett 0
 IdString GB
 Rate GBP

 $ cat it.conf
 #!/usr/bin/perl -MMyConfigDump
 inherits eu.conf
 IdString It

 $ cat pt.conf
 #!/usr/bin/perl -MMyConfigDump
 inherits eu.conf
 GMTOffsett 0
 IdString Pt

 $ cat us.conf
 #!/usr/bin/perl -MMyConfigDump
 inherits base.conf
 IdString US
 Rate USD

 $ ./base.conf
 GMTOffsett = error;
 IdString = 'MyApp';
 LogString = 'MyFacility-MyApp';

 $ ./eu.conf
 GMTOffsett = '-1';
 IdString = 'MyAppEu';
 LogString = 'MyFacility-MyAppEu';
 Rate = 'UER';

 $ ./fr.conf
 GMTOffsett = '-1';
 IdString = 'MyAppEuFr';
 LogString = 'MyFacility-MyAppEuFr';
 Rate = 'UER';

 $ ./gb.conf
 GMTOffsett = '0';
 IdString = 'MyAppEuGB';
 LogString = 'MyFacility-MyAppEuGB';
 Rate = 'GBP';

 $ ./it.conf
 GMTOffsett = '-1';
 IdString = 'MyAppEuIt';
 LogString = 'MyFacility-MyAppEuIt';
 Rate = 'UER';

 $ ./pt.conf
 GMTOffsett = '0';
 IdString = 'MyAppEuPt';
 LogString = 'MyFacility-MyAppEuPt';
 Rate = 'UER';

 $ ./us.conf
 GMTOffsett = error;
 IdString = 'MyAppUS';
 LogString = 'MyFacility-MyAppUS';
 Rate = 'USD';

=head1 BUGS AND INCOMPATIBILITIES

Some perl versions has a bug which give a message like following one:

 Attempt to free unreferenced scalar: SV 0xe7411a0, Perl interpreter: 0xe160010 at t/99_dump.t line 2 during global destruction.

If it is possible to upgrade perl version, this is the best solution, otherwise an installation workaround can be used:

 export EXCLUDE_WEAKEN=1
 cpan Config::General::Hierarchical

Please report here https://rt.cpan.org/Dist/Display.html?Name=Config-General-Hierarchical any other one.

=head1 SEE ALSO

I strongly recommend you to read the following documentations:

 Config::General         The way this module reads configuration files

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2007-2009 Daniele Ricci

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AUTHOR

Daniele Ricci <icc |AT| cpan.org>

=head1 CREDITS

A special thanks to Dada S.p.A. (Italy) for giving authorization to publish this module.

=head1 VERSION

0.07

=cut
