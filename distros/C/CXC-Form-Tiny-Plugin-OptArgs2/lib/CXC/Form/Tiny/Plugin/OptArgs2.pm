package CXC::Form::Tiny::Plugin::OptArgs2;

# ABSTRACT: A Plugin to interface Form::Tiny with OptArgs2

use v5.20;

use warnings;
use experimental 'signatures', 'postderef';

our $VERSION = '0.08';

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

            optargs_opts => sub ( @options ) {
                $caller->form_meta->_dsl_optargs_opts( $context->$*, @options );
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

=for :stopwords Diab Jerius Smithsonian Astrophysical Observatory subform cmd subcmd
subsubcmd

=head1 NAME

CXC::Form::Tiny::Plugin::OptArgs2 - A Plugin to interface Form::Tiny with OptArgs2

=head1 VERSION

version 0.08

=head1 SYNOPSIS

 package My::Form {
 
     use Form::Tiny plugins => ['+CXC::Form::Tiny::Plugin::OptArgs2'];
 
     use Types::Standard       qw( ArrayRef HashRef Str );
     use Types::Common::String qw( NonEmptyStr );
     use Types::Path::Tiny     qw( Path );
 
     # configure plugin; these are the default values
     optargs_opts( inherit_required => !!1, inherit_optargs => !!0 );
 
     form_field 'file' => ( type => NonEmptyStr, default => sub { 'file.ext' } );
 
     # the 'option' keyword immediately follows the field definition
     option(
         isa      => 'Str',               # optional, can usually guess from the field
         comment  => 'Query in a file',
         isa_name => 'ADQL in a file',
     );
 
     # arguments can appear in any order; use the 'order' attribute to
     # specify their order on the command line
 
     form_field 'arg2' => ( type => ArrayRef, );
     argument(
         isa     => 'ArrayRef',           # optional, can guess from the field
         comment => 'every thing else',
         greedy  => 1,
         order   => 2,                    # this is the second argument on the command line
     );
 
     form_field 'arg1' => ( type => Path, coerce => 1 );
     argument(
         isa     => 'Str',                # not optional, can't guess from the field
         comment => 'first argument',
         order   => 1,                    # this is the second argument on the command line
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
make it easier to use L<Form::Tiny> to validate command line options and
arguments parsed by L<OptArgs2>.

It provides new keywords to be used alongside L<Form::Tiny>'s
C<form_field> keyword to specify L<OptArgs2> options and arguments
and link them to L<Form::Tiny> fields.

It adds a method to the form's class which returns the L<OptArgs2>
compatible C<optargs> specification and another which sets the form's
input from the output of L<OptArgs2>'s C<optargs> and C<class_optargs>
functions.

=head1 USAGE

The typical steps for handling command lines with this plugin are:

=over

=item 1

Create L<Form::Tiny> forms.

=over

=item 1.

Optionally configure the plugin with L</optargs_opts>

=item 2.

Use an L</option> or L</argument> keyword after each form field to
define the L<OptArgs2> specification (but not after fields which
contain nested forms).

=back

=item 2

Extract L<OptArgs2> specification

=item 3

Parse the command line with L<OptArgs2>

=item 4

Validate the parsed values with with the L<Form::Tiny> forms.

=back

=head2 Interfacing with L<OptArgs2>

First, the L<OptArgs2> compatible C<optargs> specifications are
extracted from the form object via the C<optargs> method:

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

The C<stuff> and C<nonsense> form fields refer to nested forms; they are I<not>
added as L<OptArgs2> options.

Note that the C<option> element C<My::SubForm> does I<not> specify a
name (it can; see below).  If not specified it will be generated based
upon its parent field, so in this case the following options will be
generated for L<OptArgs2>:

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

=head2 Configuration Files

The typical steps for handling command lines with this plugin are:

=over

=item 1

Create Forms

=item 2

Extract L<OptArgs2> specification

=item 3

Parse command line with L<OptArgs2>

=item 4

Validate with Forms

=back

For I<required> options, the default behavior is for the L<OptArgs2> specifications
to inherit the C<required> attribute from their associated form field, and thus
the initial completeness check for required options is performed by L<OptArgs2>.

However, when a configuration file is used to provide values which the command
line will augment or override,  this no longer works.  L<OptArgs2> is passed only
what is on the command line, and typically the configuration file is specified
by a command line option, so the integration of the values in the configuration
file has to be performed after L<OptArgs2> parses the command line, and thus
the completeness check has to happen after that.

Now the sequence looks like this:

=over

=item Z<>3.

Parse command line with L<OptArgs2>. Do *not* check for completeness

=item Z<>3.1

Read configuration file and merge the values with those obtained from L<OptArgs2>

=item Z<>4.

Validate with Forms, checking for completeness.

=back

In this scenario, the L</inherit_required> plugin flag must be I<false>,
otherwise L<OptArgs2> will make that decision on possibly incomplete data.

[For a complete solution to this issue, check out L<App::Easer>]

=head2 Multi-level Commands

L<OptArgs2> requires separate specifications for each level of
command.  On the command line, sub-commands can accept options for all
of their higher level commands.  For example, if command I<cmd>
accepts C<--version>, so will its sub command I<subcmd>.  When
L<OptArgs2> parses the command line it returns the combined options as
a single structure, regardless of where the option is specified, e.g.

  cmd --version  subcmd ...
  cmd subcmd --version

results in the same structure.

Thus, there are more forms required to create the option
specifications for L<OptArgs2> than are required to validate the
results it retrieves from the command line.

The most straightforward way to handle this is to create a series of
layered forms, one per command layer, with the form at one layer
inheriting from the form for the next higher layer.

For example, given a command structure of I<cmd>, I<subcmd>,
I<subsubcmd>, the form structure would look like

  package Form::Cmd { ... }
  package Form::SubCmd { ...; extends 'Form::Cmd'; }
  package Form::SubSubCmd { ...; extends 'Form::SubCmd'; }

L<OptArgs2> specifications extracted from each form should only
provide options for the corresponding command; this requires that the
L</inherit_optargs> flag be I<false> so that only the specifications
for the options in that form be extracted and passed to L<OptArgs2>.

Options and arguments returned by L<OptArgs2> are collected from a
command and its parents, so are validated by the form at that
command's level, which will inherit the fields from its parent forms,
similar to how L<OptArgs2> operates.

L</inherit_optargs> defaults to I<false> so this behavior is the default.

=head2 L</optargs_opts> v.s. a Plugin.

As an alternative to specifying L</optargs_opts> at the top of the form
definition,  a L<Form::Tiny> plugin can be used:

  package My::Form::Plugin;
  use parent 'Form::Tiny::Plugin';

  sub plugin ( $self, $caller, $context ) {
    return {
      meta_roles  => [ 'My::Form::Plugin::Meta', ],
    };
  }

  package My::Form::Plugin::Meta {
    use Moo::Role;
    around inherit_optargs => sub { return !!0 };
  }

  package My::Form;
  use Form::Tiny plugins => ['+CXC::Form::Tiny::Plugin::OptArgs2','+My::Form::Plugin'];
  ...

Because this plugin wraps the attribute accessor, a form using this
plugin cannot override the value via the L</optargs_opts> keyword.

To change an attribute's default value, wrap its builder, rather than its accessor, e.g.

  package My::Form::Plugin::Meta {
    use Moo::Role;
    around _build_inherit_required => sub { return !!0 };
  }

This allows a form to use the L</optargs_opts> keyword and override
the plugin's L</inherit_required> default.

=head1 KEYWORDS

=head2 Plugin configuration

Plugin behavior for a specific form is performed via the
L</optargs_opts> keyword, which must appear before any L</option> or
L</argument> keywords.

=head3 optargs_opts

This takes a list of named attributes, which may include
the following:

=over

=item inherit_required      => Optional [Bool],

This flag determines whether C<options> inherit the C<required> flag
from their associated form field.  It defaults to C<true>.  See
L</Configuration Files> for a discussion of where this may not be
useful.

=item inherit_optargs       => Optional [Bool],

This flag determines whether a child form inherits the options and
arguments of its parent.  (This differs from nested forms, which
appear as the values of form fields).  If a inheritance hierarchy is
used to model command / sub-command configuration options, then it is
best to I<not> inherit the options, as L<OptArgs2> will automatically
create that hierarchy, and having this plugin do so will cause options
to appear duplicated.  See L</Multilevel Commands>.

=item inherit_optargs_match => Optional [ArrayRef],

This parameter provides some flexibility in specifying which parent
forms to include or exclude when inheriting options and arguments.

It is takes an array of regular expressions and include/exclude flags
(C<->, C<+>) which are matched against the classes in the form's
C<@ISA> array.  The first regular expression which matches determines
whether the parent class is included or excluded.

For example, if the match list is

  [ qr/Form0/, '-', qr/Form1/ ]

each class is first compared to C<qr/Form0/>; if that succeeds the
process stops and the class is included (the C<+> is
implicit). Otherwise the process continues with C<qr/Form1/>; if that
matches it is excluded (because of the immediately preceding C<->
flag).

What happens if a class doesn't match anything in the list?  If the
list is composed only of I<included> regexps, then it will be excluded.
If at least one I<excluded> regexp is in the list, it will be included.

Match lists can be nested, and each match list can be preceded by an
include/exclude flag to specify the default behavior for matches. For example,

  [ qr/Form1/, '-', [ qr/Form2/, qr/Form3/ ] ]

results in one included regexp and two excluded ones.

=back

=head2 Specifying options and arguments.

Option and argument specifications use the C<option> and C<argument>
DSL keywords.  They must I<immediately> follow the definition of their
associated L<Form::Tiny> fields (see L</SYNOPSIS>).

=head3 L<option>

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

=head3 L<argument>

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

(This behavior is regulated  the L</inherit_required> attribute passed to
the L</optargs_opts> keyword.)

L<OptArgs2> has a simpler concept of a required element than does
L<Form::Tiny>.  If the field's required attribute is false, the option
or argument's value is set to false, otherwise it is set to true.

=head1 SUPPORT

=head2 Bugs

Please report any bugs or feature requests to bug-cxc-form-tiny-plugin-optargs2@rt.cpan.org  or through the web interface at: L<https://rt.cpan.org/Public/Dist/Display.html?Name=CXC-Form-Tiny-Plugin-OptArgs2>

=head2 Source

Source is available at

  https://gitlab.com/djerius/cxc-form-tiny-plugin-optargs2

and may be cloned from

  https://gitlab.com/djerius/cxc-form-tiny-plugin-optargs2.git

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2023 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
