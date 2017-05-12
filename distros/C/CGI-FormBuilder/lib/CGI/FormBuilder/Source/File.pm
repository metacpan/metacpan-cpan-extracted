
###########################################################################
# Copyright (c) Nate Wiger http://nateware.com. All Rights Reserved.
# Please visit http://formbuilder.org for tutorials, support, and examples.
###########################################################################

package CGI::FormBuilder::Source::File;

=head1 NAME

CGI::FormBuilder::Source::File - Initialize FormBuilder from external file

=head1 SYNOPSIS

    # use the main module
    use CGI::FormBuilder;

    my $form = CGI::FormBuilder->new(source => 'form.conf');

    my $lname = $form->field('lname');  # like normal

=cut

use Carp;
use strict;
use warnings;
no  warnings 'uninitialized';

use 5.006; # or later
use CGI::FormBuilder::Util;


our $VERSION = '3.10';

# Begin "real" code
sub new {
    my $mod = shift;
    my $class = ref($mod) || $mod;
    my %opt = arghash(@_);
    return bless \%opt, $class;
}

sub parse {
    local $^W = 0;  # -w sucks so hard
    my $self = shift;
    my $file = shift || $self->{source};

    $CGI::FormBuilder::Util::DEBUG ||= $self->{debug} if ref $self;

    my $ret = {};   # top level
    my $ptr = $ret; # curr ptr
    my @lvl = ();   # previous levels

    my $s   = 0;    # curr spaces
    my $lsp = 0;    # level spaces
    my $psp = 0;    # prev spaces

    my $refield = 0;
    my @file;
    my $utf8 = 0;   # parse file as utf8

    debug 1, "parsing $file as input source";
    if (ref $file eq 'SCALAR') {
        @file = split /[\r\n]+/, $$file;
    } elsif (ref $file eq 'ARRAY') {
        @file = @$file;
    } else {
        open(F, "<$file") || puke "Cannot read $file: $!";
        @file = <F>;
        close F;
    }

    my($lterm, $here);  # level term, here string
    my $inval = 0;
    for (@file) {
        next if /^\s*$/ || /^\s*#/;     # blanks and comments
        next if /^\s*\[\%\s*\#|^\s*-*\%\]/;   # TT comments too
        chomp;
        my($term, $line) = split /\s*:\s*/, $_, 2;
        $utf8 = 1 if $term eq 'charset' && $line =~ /^utf/;  # key off charset to decode value
        $line = Encode::decode('utf-8', $line) if $utf8;

        # here string term-inator (har)
        if ($here) {
            if ($term eq $here) {
                undef $here;
                next;
            } else {
                $line = $term;
                $term = $lterm;
            }
        } else {
            # count leading space if it's there
            $s = 1;     # reset
            $s += length($1) if $term =~ s/^(\s+)//;
            $line =~ s/\s+$//;       # trailing space

            # uplevel pre-check (may have a value below)
            if ($s == 1) {
                $ptr = $ret;
                @lvl = ();
                $lsp = 1;       # set to zero for next pass
                $refield = 0;
                $inval = 0;
            } elsif ($s <= $lsp) {
                $ptr = pop(@lvl) || $ret;
                $lsp = $s;      # uplevel term indent
                $inval = 0;
            }

            # special catch for continued (indented) line
            if ($s >= $psp && $inval && ! length $line) {
                $line = $term;
                $term = $lterm;
            }
            debug 2, "[$s >= $psp, inval=$inval] term=$term; line=$line";
        }
        $psp = $s;

        # has a value
        if (length $line) {
            debug 2, "$term = $line ($s < $lsp)";

            $lsp ||= $s;    # first valid term indent

            # <<HERE strings bypass all subsequent parsing
            if ($line =~ /^<<(.+)/) {
                $lterm = $term;
                $here  = $1;
                next;
            } elsif ($here) {
                $ptr->{$term} .= "$line\n";
                next;
            }

            my @val;
            if ($term =~ /^js/ || $term =~ /^on[a-z]/ || $term eq 'messages' || $term eq 'comment') {
                @val = $line;   # verbatim
            } elsif ($line =~ s/^\\(.)//) {
                # Reference - this is tricky. Go all the way up to
                # the top to make sure, or use $self->{caller} if
                # we were given a place to go.
                my $r = $1;
                my $l = 0;
                my @p;
                if ($self->{caller}) {
                    @p = $self->{caller};
                } else {
                    while (my $pkg = caller($l++)) {
                        push @p, $pkg;
                    }
                }
                $line = "$r$p[-1]\::$line" unless $line =~ /::/;
                debug 2, qq{eval "\@val = (\\$line)"};
                eval "\@val = (\\$line)";
                belch "Loading $line failed: $@" if $@;
            } else {
                # split commas
                @val = split /\s*,\s*/, $line;

                # m=Male, f=Female -> [m,Male], [f,Female]
                for (my $i=0; $i < @val; $i++) {
                    $val[$i] = [ split /\s*=\s*/, $val[$i], 2 ] if $val[$i] =~ /=/;
                }
            }

            # only arrayref on multi values b/c FB is "smart"
            if ($ptr->{$term}) {
                $ptr->{$term} = (ref $ptr->{$term})
                                    ? [ @{$ptr->{$term}}, @val ] : @val > 1 ? \@val :
                                      ref($val[0]) eq 'ARRAY' ? \@val : $val[0];
            } else {
                $ptr->{$term} = @val > 1 ? \@val : ref($val[0]) eq 'ARRAY' ? \@val : $val[0];
            }
            $inval = 1;
        } else {
            debug 2, "$term: new level ($s < $lsp)";

            # term:\n -> nest with bracket
            if ($term eq 'fields') {
                $refield = 1;
                $term = 'fieldopts';
            } elsif ($refield) {
                push @{$ret->{fields}}, $term;
            }

            $ptr->{$term} ||= {};
            push @lvl, $ptr;
            $ptr = $ptr->{$term};

            $lsp = $s;       # reset spaces
            $inval = 0;
        }
        $lterm = $term;
    }

    if (ref $self) {
        # add in any top-level options
        while (my($k,$v) = each %$self) {
            $ret->{$k} = $v unless exists $ret->{$k};
        }

        # in FB, this is a class (not object) for speed
        $self->{data}   = $ret;
        $self->{source} = $file;
    }

    return wantarray ? %$ret : $ret;
}

sub write_module {
    my $self = shift;
    my $mod  = shift || puke "Missing required Module::Name";
    (my $out = $mod) =~ s/.+:://;
    $out .= '.pm';

    open(M, ">$out") || puke "Can't write $out: $!";

    print M "\n# Generated ".localtime()." by ".__PACKAGE__." $VERSION\n";
    print M <<EOH;
#
# To use this, you must write a script and then use this module.
# In your script, get this form with "my \$form = $mod->new()"

package $mod;

use CGI::FormBuilder;
use strict;

sub new {
    # $mod->new() calling format
    my \$self = shift if \@_ && \@_ % 2 != 0;

    # data structure from '$self->{source}'
EOH

    require Data::Dumper;
    local $Data::Dumper::Varname = 'form';
    print M "    my ". Data::Dumper::Dumper($self->{data});

    print M <<'EOV';

    # allow overriding of individual parameters
    while (@_) {
        $form1->{shift()} = shift;
    }

    # return a new form object
    return CGI::FormBuilder->new(%$form1);
}

1;
# End of module
EOV

    close M;
    print STDERR "Wrote $out\n";    # send to stderr in case of httpd
}

1;
__END__

=head1 DESCRIPTION

This parses a file that contains B<FormBuilder> configuration options,
and returns a hash suitable for creating a new C<$form> object.
Usually, you should not use this directly, but instead pass a C<$filename>
into C<CGI::FormBuilder>, which calls this module.

The configuration format steals from Python (ack!) which is sensitive to
indentation and newlines. This saves you work in the long run. Here's
a complete form:

    # form basics
    method: POST
    header: 1
    title:  Account Information

    # define fields
    fields:
        fname:
            label:   First Name
            size:    40

        minit:
            label:   Middle Initial
            size:    1

        lname:
            label:   Last Name
            size:    60

        email:
            size:    80

        phone:
            label:    Home Phone
            comment:  (optional)
            required: 0

        sex:
            label:   Gender
            options: M=Male, F=Female
            jsclick: javascript:alert('Change your mind??')

        # custom options and sorting sub
        state:
            options:  \&getstates
            sortopts: \&sortstates

        datafile:
            label:   Upload Survey Data
            type:    file
            growable:   1

    # validate our above fields
    validate:
        email:  EMAIL
        phone:  /^1?-?\d{3}-?\d{3}-?\d{4}$/

    required: ALL

    # create two submit buttons, and skip validation on "Cancel"
    submit:  Update, Cancel
    jsfunc:  <<EOJS
  // skip validation
  if (this._submit.value == 'Cancel') return true;
EOJS

    # CSS
    styleclass: acctInfoForm
    stylesheet: /style/acct.css

Any option that B<FormBuilder> accepts is supported by this
configuration file. Basically, any time that you would place
a new bracket to create a nested data structure in B<FormBuilder>,
you put a newline and indent instead.

B<Multiple options MUST be separated by commas>. All whitespace
is preserved intact, so don't be confused and do something
like this:

    fields:
        send_me_emails:
            options: Yes No

Which will result in a single "Yes No" option. You want:

    fields:
        send_me_emails:
            options: Yes, No

Or even better:

    fields:
        send_me_emails:
            options: 1=Yes, 0=No

Or perhaps best of all:

    fields:
        send_me_emails:
            options: 1=Yes Please, 0=No Thanks

If you're confused, please join the mailing list:

    fbusers-subscribe@formbuilder.org

We'll be able to help you out.

=head1 METHODS

=head2 new()

This creates a new C<CGI::FormBuilder::Source::File> object.

    my $source = CGI::FormBuilder::Source::File->new;

Any arguments specified are taken as defaults, which the file
then overrides. For example, to always turn off C<javascript>
(so you don't have to in all your config files), use:

    my $source = CGI::FormBuilder::Source::File->new(
                      javascript => 0
                 );

Then, every file parsed by C<$source> will have C<< javascript => 0 >>
in it, unless that file has a C<javascript:> setting itself.

=head2 parse($source)

This parses the specified source, which is either a C<$file>,
C<\$string>, or C<\@array>, and returns a hash which can
be passed directly into C<CGI::FormBuilder>:

    my %conf = $source->parse('myform.conf');
    my $form = CGI::FormBuilder->new(%conf);

=head2 write_module($modname)

This will actually write a module in the current directory 
which you can then use in subsequent scripts to get the same
form:

    $source->parse('myform.conf');
    $source->write_module('MyForm');    # write MyForm.pm

    # then in your Perl code
    use MyForm;
    my $form = MyForm->new;

You can also override settings from C<MyForm> the same as you
would in B<FormBuilder>:

    my $form = MyForm->new(
                    header => 1,
                    submit => ['Save Changes', 'Abort']
               );

This will speed things up, since you don't have to re-parse
the file every time. Nice idea Peter.

=head1 NOTES

This module was completely inspired by Peter Eichman's 
C<Text::FormBuilder>, though the syntax is different.

Remember that to get a new level in a hashref, you need
to add a newline and indent. So to get something like this:

    table => {cellpadding => 1, cellspacing => 4},
    td    => {align => 'center', bgcolor => 'gray'},
    font  => {face => 'arial,helvetica', size => '+1'},

You need to say:

    table:
        cellpadding: 1
        cellspacing: 4

    td:
        align: center
        bgcolor: gray

    font:
        face: arial,helvetica
        size: +1

You get the idea...

=head1 SEE ALSO

L<CGI::FormBuilder>, L<Text::FormBuilder>

=head1 REVISION

$Id: File.pm 100 2007-03-02 18:13:13Z nwiger $

=head1 AUTHOR

Copyright (c) L<Nate Wiger|http://nateware.com>. All Rights Reserved.

This module is free software; you may copy this under the terms of
the GNU General Public License, or the Artistic License, copies of
which should have accompanied your Perl kit.

=cut
