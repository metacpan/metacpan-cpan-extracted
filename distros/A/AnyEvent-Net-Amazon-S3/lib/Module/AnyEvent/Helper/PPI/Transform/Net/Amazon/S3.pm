package Module::AnyEvent::Helper::PPI::Transform::Net::Amazon::S3;

# ABSTRACT: Additional transformer for Module::AnyEvent::Helper
our $VERSION = 'v0.04.0.80'; # VERSION

use strict;
use warnings;

use parent qw(PPI::Transform::PackageName);

sub new
{
    my ($self) = @_;
    my $ret = $self->SUPER::new(
        -all => sub {
            s/^Net::Amazon::S3\b/AnyEvent::Net::Amazon::S3/g;
            s/^LWP::UserAgent\b/AnyEvent::HTTP::LWP::UserAgent/g;
            s/^Data::Stream::Bulk::Callback\b/Data::Stream::Bulk::AnyEvent/g;
        }
    );
    return $ret;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Module::AnyEvent::Helper::PPI::Transform::Net::Amazon::S3 - Additional transformer for Module::AnyEvent::Helper

=head1 VERSION

version v0.04.0.80

=head1 SYNOPSIS

  use Module::AnyEvent::Helper::Filter -transformer => 'Net::Amazon::S3', -target => 'Net::Amazon::S3';

=head1 DESCRIPTION

This class is not intended to use directly.

=head1 AUTHOR

Yasutaka ATARASHI <yakex@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Yasutaka ATARASHI.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
