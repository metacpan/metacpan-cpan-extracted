package Code::TidyAll::Plugin::PgFormatter;

our $VERSION = '0.01';

use IPC::Run3 qw( run3 );
use Moo;

extends 'Code::TidyAll::Plugin';

sub _build_cmd { 'pg_format' }

sub transform_source {
    my ( $self, $source ) = @_;

    # want pg_format to run from stdin
    my @cmd = ( $self->cmd, split(/\s+/, $self->argv ), q{-} );

    my $output;
    my $err;
    run3( \@cmd, \$source, \$output, \$err);

    if ( $? > 0 ) {
	$err ||= "problem running " . $self->cmd;
        die $err;
    }

    return $output;
}

1;
__END__

=encoding utf-8

=head1 NAME

Code::TidyAll::Plugin::PgFormatter - Code::TidyAll plugin for pg_format

=head1 SYNOPSIS

  In your tidyall config:

  [PgFormatter]
  select = **/*sql
  ; affects formatted output, defaults for pg_format shown
  argv = --function-case 0 --keyword-case 2 --spaces 4

=head1 DESCRIPTION

Code::TidyAll::Plugin::PgFormatter is a plugin for Code::TidyAll that will call
pg_format from the L<https://sourceforge.net/p/pgformatter/> project, and
nicely-format your SQL files.

=head1 INSTALLATION

Following the installation instructions in the github project page:
<https://github.com/darold/pgFormatter>

Note that CGI is required by pg_format, you may need to install it in
more-recent versions of perl.

  cpanm CGI

=head1 CONFIGURATION

=over

=item argv

Arguments to pass to pg_format.  See the pgFormatter documentation for
command-line options.

=back

=head1 AUTHOR

Andy Jack E<lt>andyjack@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2015- Andy Jack

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Code::TidyAll>

=cut
