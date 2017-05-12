package Dancer2::Plugin::AppRole::LogContextualWarn;

use strictures 2;

use Log::Contextual ':log';

use Moo::Role;

our $VERSION = '1.152121'; # VERSION

# ABSTRACT: role to force all warns in a Dancer2 plack app to log_warn

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
        local $SIG{__WARN__} = sub {
            my @args = @_;
            log_warn { @args };
        };
        return $app->( @_ );
    };
};

1;

__END__

=pod

=head1 NAME

Dancer2::Plugin::AppRole::LogContextualWarn - role to force all warns in a Dancer2 plack app to log_warn

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
