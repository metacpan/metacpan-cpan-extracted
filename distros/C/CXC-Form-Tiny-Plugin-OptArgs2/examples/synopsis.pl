#! /bin/perl
use v5.10;

# example-barrier

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
