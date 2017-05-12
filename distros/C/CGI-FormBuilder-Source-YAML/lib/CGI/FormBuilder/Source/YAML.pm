package CGI::FormBuilder::Source::YAML;

use strict;
use warnings;

use YAML::Syck;

use CGI::FormBuilder::Util;

our $VERSION = '1.0008';

sub new {
    my $self  = shift;
    my $class = ref($self) || $self;
    my %opt   = @_;
    return bless \%opt, $class;
}

sub parse {
    my $self = shift;
    my $file = shift || $self->{source};

    local $YAML::Syck::LoadCode = 1;
    local $YAML::Syck::UseCode = 1;
    local $YAML::Syck::DumpCode = 1;

    $CGI::FormBuilder::Util::DEBUG ||= $self->{debug} if ref $self;

    puke("file must be only one scalar file name") if ref $file;

    my $formopt = LoadFile($file);
    puke("loaded file '$file' is not hashref") if ref $formopt ne 'HASH';

    debug 1, "processing YAML::Syck file '$file' as input source";

    # add in top-level options:
    map { $formopt->{$_} = $self->{$_} if !exists $formopt->{$_} } keys %{$self};

    # whork in the function refs:
    $self->_assign_references($formopt, 1) if ref $self;

    my %lame = ( %{$formopt} );
    debug 1, "YAML form definition is:", Dump(\%lame);

    return wantarray ? %{$formopt} : $formopt;
}

sub _assign_references {
    my ($self, $hashref, $stacklevel) = @_;
    $stacklevel++;

    NODE:
    foreach my $node (values %{$hashref}) {
        my $ref = ref $node;

        if ($ref eq 'HASH') {
            $self->_assign_references($node, $stacklevel);
        }
        elsif (!$ref) {

            debug 1, "node is '$node'\n";

            if ( $node =~ m{ \A \\ ([&\$%@]) (.*) \z }xms ) {

                my ($reftype, $refstr) = ($1, $2);
           
                if ($refstr =~ m{ :: }xms) {
                    # already know where it is.  assign it.
                    my $subref = undef;
                    debug 1, "assigning direct pkg ref for '$reftype$refstr'";
                    eval "\$subref = \\$reftype$refstr";
                    my $err = $@;
                    debug 1, "eval error '$err'" if $err;
                    debug 1, "subref is '$subref'";
                    $node = $subref;
                }
                else {
    
                    my $l = $stacklevel;
                    my $subref = undef;
                    LEVELUP:
                    while (my $pkg = caller($l++)) {
                        debug 1, "looking up at lev $l for ref '$refstr' in '$pkg'";
                        my $evalstr = "\$subref = \\$reftype$pkg\::$refstr";
                        debug 1, "eval '$evalstr'";
                        eval $evalstr;
                        if (!$@) {
                            $node = $subref;
                            last LEVELUP;
                        }
                    }
                }
                debug 1, "assgnd ref '$node' for '$reftype$refstr'";
            }
            elsif ( $node =~ m/ \A eval \s* { (.*) } \s* \z /xms ) {
                my $evalstr = $1;
                debug 1, "eval '$evalstr'";
                my $result = eval $evalstr;
                my $err = $@;
                if ($err) {
                    debug 1, "eval error '$err'";
                }
                else {
                    debug 1, "assgnd ref '$node' for eval";
                    $node = $result;
                }
            }

        }
    }
    return;
}

1;

=head1 NAME

CGI::FormBuilder::Source::YAML - Initialize FormBuilder from YAML file

=head1 SYNOPSIS

 use CGI::FormBuilder;

 my $form = CGI::FormBuilder->new(
    source  => {
        source  => 'form.fb',
        type    => 'YAML',
    },
 );

 my $lname = $form->field('lname');  # like normal

=head1 DESCRIPTION

This reads a YAML (YAML::Syck) file that contains B<FormBuilder>
config options and returns a hash to be fed to CGI::FormBuilder->new().

Instead of the syntax read by CGI::FormBuilder::Source::File,
it uses YAML syntax as read by YAML::Syck.  That means you
fully specify the entire data structure.

LoadCode is enabled, so you can use YAML syntax for defining subroutines.
This is convenient if you have a function that generates validation
subrefs, for example, I have one that can check profanity using Regexp::Common.

 validate:
    myfield:    
        javascript: /^[\s\S]{2,50}$/
        perl: !!perl/code: >-
            {   My::Funk::fb_perl_validate({ 
                    min         => 2, 
                    max         => 50, 
                    profanity   => 'check' 
                })->(shift);
            }

=head1 POST PROCESSING

There are two exceptions to "pure YAML syntax" where this module
does some post-processing of the result.

=head2 REFERENCES (ala CGI::FormBuilder::Source::File)

You can specify references as string values that start with 
\&, \$, \@, or \% in the
same way you can with CGI::FormBuilder::Source::File.  If you have
a full direct package reference, it will look there, otherwise
it will traverse up the caller stack and take the first it finds.

For example, say your code serves multiple sites, and a menu 
gets different options depending on the server name requested:

 # in My::Funk:
 our $food_options = {
     www.meats.com   => [qw( beef    chicken horta   fish    )],
     www.veggies.com => [qw( carrot  apple   quorn   radish  )],
 };

 # in source file:
 options: \@{ $My::Funk::food_options->{ $ENV{SERVER_NAME} } }

=head2 EVAL STRINGS

You can specify an eval statement.  You could achieve the same
example a different way:

 options: eval { $My::Funk::food_options->{ $ENV{SERVER_NAME} }; }

The cost either way is about the same -- the string is eval'd.

=head1 EXAMPLE

 method:     GET
 header:     0
 title:      test
 name:       test
 action:     /test
 submit:     test it
 linebreaks: 1

 required:   
    - test1
    - test2

 fields:
    - test1
    - test2
    - test3
    - test4

 fieldopts:
    test1:
        type:       text
        size:       10
        maxlength:  32

    test2:
        type:       text
        size:       10
        maxlength:  32

    test3:
        type:       radio
        options:
            -
                - 1
                - Yes
            -
                - 0
                - No

    test4:
        options:    \@test4opts
        sort:       \&Someother::Package::sortopts

 validate:
    test1:      /^\w{3,10}$/
    test2:
        javascript: EMAIL
        perl:       eq 'test@test.foo'
    test3:
        - 0
        - 1
    test4:  \@test4opts

You get the idea.  A bit more whitespace, but it works in a 
standardized way.

=head1 METHODS

=head2 new()

Normally not used directly; it is called from CGI::FormBuilder.
Creates the C<CGI::FormBuilder::Source::YAML> object.  Arguments
from the 'source' hash passed to CGI::FormBuilder->new() will 
become defaults, unless specified in the file.

=head2 parse($source)

Normally not used directly; it is called from CGI::FormBuilder.
Parses the specified source file.  No fancy params -- 
just a single filename is accepted.  If the file isn't
acceptable to YAML::Syck, I suppose it will die.

=head1 SEE ALSO

L<CGI::FormBuilder>, L<CGI::FormBuilder::Source>

=head1 AUTHOR

Copyright (c) 2006 Mark Hedges <hedges@ucsd.edu>. All rights reserved.

=head1 LICENSE

This module is free software; you may copy it under terms of
the Perl license (GNU General Public License or Artistic License.)
http://www.opensource.org/licenses/index.html

=cut
