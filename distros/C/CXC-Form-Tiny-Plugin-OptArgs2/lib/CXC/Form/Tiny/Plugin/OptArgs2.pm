package CXC::Form::Tiny::Plugin::OptArgs2;

# ABSTRACT: A Plugin to interface Form::Tiny with OptArgs2

use v5.20;

use warnings;
use experimental 'signatures', 'postderef';

our $VERSION = '0.04';

use parent 'Form::Tiny::Plugin';

## no critic (Subroutines::ProtectPrivateSubs)

sub plugin ( $self, $caller, $context ) {
    return {
        roles      => [ q{CXC::Form::Tiny::Plugin::OptArgs2::Class}, ],
        meta_roles => [ q{CXC::Form::Tiny::Plugin::OptArgs2::Meta}, ],
        subs       => {
            option => sub ( @options ) {
                $caller->form_meta->_dsl_add_option( $context->$*, @options );
            },

            argument => sub ( @options ) {
                $caller->form_meta->_dsl_add_argument( $context->$*, @options );
            },
        },

    };
}

#
# This file is part of CXC-Form-Tiny-Plugin-OptArgs2
#
# This software is Copyright (c) 2023 by Smithsonian Astrophysical Observatory.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#

1;

__END__

=pod

=for :stopwords Diab Jerius Smithsonian Astrophysical Observatory subform

=head1 NAME

CXC::Form::Tiny::Plugin::OptArgs2 - A Plugin to interface Form::Tiny with OptArgs2

=head1 VERSION

version 0.04

=head1 SYNOPSIS

 package My::Form {
 
     use Form::Tiny plugins => ['+CXC::Form::Tiny::Plugin::OptArgs2'];
 
     use Types::Standard       qw( ArrayRef HashRef Str );
     use Types::Common::String qw( NonEmptyStr );
 
     form_field 'file' => ( type => NonEmptyStr, default => sub { 'file.ext' } );
 
     # the 'option' keyword immediately follows the field definition
     option(
         isa      => 'Str',
         comment  => 'Query in a file',
         isa_name => 'ADQL in a file',
     );
 
     # arguments can appear in any order; use the 'order' attribute to
     # specify their order on the command line
 
     form_field 'arg2' => ( type => ArrayRef, );
     argument(
         isa     => 'ArrayRef',
         comment => 'every thing else',
         greedy  => 1,
         order   => 2,
     );
 
     form_field 'arg1' => ( type => NonEmptyStr, );
     argument(
         isa     => 'Str',
         comment => 'first argument',
         order   => 1,
     );
 
 }
 
 use OptArgs2;
 use Data::Dumper;
 
 # create form
 my $form = My::Form->new;
 
 # parse command line arguments and validate them with the form
 @ARGV = qw( --file x.y.z val1 val2 val3 );
 $form->set_input_from_optargs(
     optargs( comment => 'this program is cool', optargs => $form->optargs ) );
 die Dumper( $form->errors_hash ) unless $form->valid;
 
 say $form->fields->{file};       # x.y.z
 say $form->fields->{arg1};       # val1
 say $form->fields->{arg2}[0];    # val2
 say $form->fields->{arg2}[1];    # val3

results in

 x.y.z
 val1
 val2
 val3

=head1 DESCRIPTION

C<CXC::Form::Tiny::Plugin::OptArgs2> is a L<Form::Tiny> plugin which
make it easier to use Form::Tiny to validate command line options and
arguments parsed by L<OptArgs2>.

It provides two new keywords to be used alongside L<Form::Tiny>'s
C<form_field> keyword which provide L<OptArgs2> option and argument
specifications and link them to L<Form::Tiny> fields.

It adds a method to the form's class which returns the L<OptArgs2>
compatible C<optargs> specification and another which sets the form's
input from the output of L<OptArgs2>'s C<optargs> and C<class_optargs>
functions.

=head1 USAGE

=head2 Specifying options and arguments.

Option and argument specifications use the C<option> and C<argument>
DSL keywords.  They must I<immediately> follow the definition of their
associated L<Form::Tiny> fields (see L</SYNOPSIS>).

=head3 Options

The C<option> keyword takes a list of named attributes with the
following accepted names and value types (refer to L<OptArgs2> for
their meaning):

        name         => Optional [NonEmptySimpleStr],
        alias        => Optional [NonEmptySimpleStr],
        comment      => NonEmptySimpleStr,
        default      => Optional [Value|CodeRef],
        required     => Optional [Bool],
        hidden       => Optional [Bool],
        isa          => Optional [Enum[ qw( ArrayRef Flag Bool Counter HashRef Int Num Str ) ] ],
        isa_name     => Optional [NonEmptySimpleStr],
        show_default => Optional [Bool],
        trigger      => Optional [CodeRef],

Unlike in L<OptArgs2>, a leading prefix of C<--> in the
value of the C<isa> attribute is optional.

=head3 Arguments

The C<argument> keyword takes a list of named attributes with the
following accepted names and value types (refer to L<OptArgs2> for
their meaning, except for C<order>):

        name         => Optional [NonEmptySimpleStr],
        comment      => NonEmptySimpleStr,
        default      => Optional [Value|CodeRef],
        greedy       => Optional [Bool],
        fallthru     => Optional [Bool],
        isa          => Optional [Enum [qw( ArrayRef HashRef Int Num Str SubCmd)]],
        isa_name     => Optional [NonEmptySimpleStr],
        required     => Optional [Bool],
        show_default => Optional [Bool],
        order        => Int,

The C<order> attribute specifies the relative order the argument
should appear on the command line.  This allows the form fields to be
specified in an arbitrary order.

=head3 Automatic determination of OptArgs2 attributes

=head4 C<name>

C<name> will be taken from the immediately preceding C<form_field>
specification if not provided.  The form field and option names need
not be the same.

=head4 C<isa>

The C<isa> option can be omitted in the list of option and argument
attributes if the L<OptArgs2> type can be deduced from the
L<Form::Tiny> type.  The types which require explicit specification
are the L<OptArgs2> C<Flag>, C<Counter>, and C<SubCmd> types.

=head4 C<required>

L<OptArgs2> has a simpler concept of a required element than does
L<Form::Tiny>.  If the field's required attribute is false, the option
or argument's value is set to false, otherwise it is set to true.

=head2 Interfacing with L<OptArgs2>

There are two components to interfacing with L<OptArgs2>.  First, the
L<OptArgs2> compatible C<optargs> specifications are extracted from
the form object via the C<optargs> method:

   my $form = My::Form->new;
   my \@optargs = $form->optargs;

These are then passed on to L<OptArgs2> via either the C<optargs>,
C<cmd> functions, or C<subcmd> functions, e.g.

   my $opts = optargs( comment => 'a comment', optargs => \@optargs );

Finally, the parsed results are passed back to the form for validation:

   $form->set_input_from_optargs( $opts );
   die unless $form->valid;

=head2 Nested Forms

Consider this structure:

  package My::SubForm {
    ...

    form_field 'upload' => ( type => HashRef[Str] );
    option ( isa => 'HashRef', ... )
  }

  package My::Form {
    ...

    form_field 'stuff' => ( type => My::SubForm->new );
    form_field 'nonsense => ( type => My::SubForm->new );
  }

The C<option> element C<My::SubForm> does I<not> specify a name.  In
this case,  the following options will be generated for L<OptArgs2>:

  --stuff_upload
  --stuff_nonsense

and when the validated form data is retrieved via C<$form->fields>, it
will look like:

   { stuff => { upload => { ... } },
     nonsense => { upload => { ... } }
   }

If the C<option> element I<did> specify a name, then the automatic creation
of the hierarchical names would not be done, and the repeated use of the subform
would result in duplicate option names, and an exception would (hopefully) be thrown.

=head1 LIMITATIONS

The use of this plugin with complex multi-level L<OptArgs2> command
specifications has not been investigated.

=head1 SUPPORT

=head2 Bugs

Please report any bugs or feature requests to bug-cxc-form-tiny-plugin-optargs@rt.cpan.org  or through the web interface at: L<https://rt.cpan.org/Public/Dist/Display.html?Name=CXC-Form-Tiny-Plugin-OptArgs>

=head2 Source

Source is available at

  https://gitlab.com/djerius/cxc-form-tiny-plugin-optargs

and may be cloned from

  https://gitlab.com/djerius/cxc-form-tiny-plugin-optargs.git

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2023 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
