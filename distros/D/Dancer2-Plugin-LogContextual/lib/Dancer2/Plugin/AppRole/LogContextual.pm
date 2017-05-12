package Dancer2::Plugin::AppRole::LogContextual;

use strictures 2;

use Log::Contextual 'with_logger';

use Moo::Role;

our $VERSION = '1.152121'; # VERSION

# ABSTRACT: role to wrap a Dancer2 plack app in the configured Log::Contextual logger

#
# This file is part of Dancer2-Plugin-LogContextual
#
#
# Christian Walde has dedicated the work to the Commons by waiving all of his
# or her rights to the work worldwide under copyright law and all related or
# neighboring legal rights he or she had in the work, to the extent allowable by
# law.
#
# Works under CC0 do not require attribution. When citing the work, you should
# not imply endorsement by the author.
#

around to_app => sub {
    my ( $attr, $self, @args ) = @_;
    my $app = $self->$attr( @args );
    return sub {
        my @app_args = @_;
        my $logger   = $self->setting( "lc_logger" );
        return $logger
          ? with_logger $logger => sub { $app->( @app_args ) }
          : $app->( @app_args );
    };
};

1;

__END__

=pod

=head1 NAME

Dancer2::Plugin::AppRole::LogContextual - role to wrap a Dancer2 plack app in the configured Log::Contextual logger

=head1 VERSION

version 1.152121

=head1 AUTHOR

Christian Walde <walde.christian@gmail.com>

=head1 COPYRIGHT AND LICENSE


Christian Walde has dedicated the work to the Commons by waiving all of his
or her rights to the work worldwide under copyright law and all related or
neighboring legal rights he or she had in the work, to the extent allowable by
law.

Works under CC0 do not require attribution. When citing the work, you should
not imply endorsement by the author.

=cut
