package Catalyst::Helper::Model::DBR;

our $VERSION = '1.0';

sub mk_compclass {
    my ( $self, $helper, $conf, $schema ) = @_;
    $helper->{dbrconf} = $conf   || die "/path/to/DBR.conf is required";
    $helper->{schema}  = $schema || '';

    my $file = $helper->{file};
    $helper->render_file( 'dbrclass', $file );
    return 1;
}

=head1 NAME

Catalyst::Helper::Model::DBR - Helper for DBR Models

=head1 SYNOPSIS

    script/create.pl model DBI DBI dsn user password

=head1 DESCRIPTION

Helper for DBR Model.

=head2 METHODS

=over 4

=item mk_compclass

Reads the database and makes a main model class

=back

=head1 SEE ALSO

L<Catalyst::Manual>, L<Catalyst::Test>, L<Catalyst::Request>,
L<Catalyst::Response>, L<Catalyst::Helper>

=head1 AUTHOR

Daniel Norman, C<impious@cpan.org>

=head1 LICENSE

This library is free software . You can redistribute it and/or modify
it under the same terms as perl itself.

=cut

1;
__DATA__

__dbrclass__
package [% class %];
use parent 'Catalyst::Model::DBR';

__PACKAGE__->config(
    dbrconf       => '[% dbrconf %]',
    schema_name   => '[% schema %]',
    autoload_ok   => 1, # Only kicks in if schema is specified
);

=pod

=head1 NAME

[% class %] - DBI Model Class

=head1 SYNOPSIS

See L<[% app %]>

=head1 DESCRIPTION

DBI Model Class.

=head1 AUTHOR

[% author %]

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
