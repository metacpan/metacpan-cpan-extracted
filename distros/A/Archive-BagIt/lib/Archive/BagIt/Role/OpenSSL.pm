package Archive::BagIt::Role::OpenSSL;
use strict;
use warnings;
use Archive::BagIt::Role::OpenSSL::Sync;
use Class::Load qw(load_class);
use Carp qw(carp);
use Moo::Role;
use namespace::autoclean;
# ABSTRACT: A role that handles plugin loading
our $VERSION = '0.091'; # VERSION


has 'async_support' => (
    is        => 'ro',
    builder   => '_check_async_support',
    predicate => 1,
    lazy      => 1,
);

sub _check_async_support {
    my $self = shift;
    if (! exists $INC{'IO/Async.pm'}) {
        carp "Module 'IO::Async' not available, disable async support";
        $self->bagit->use_async(0);
        return 0;
    }
    load_class('IO::Async');
    return 1;
}



sub _get_hash_string_sync {
    my ($self, $fh, $blksize)=@_;
    my $obj = Archive::BagIt::Role::OpenSSL::Sync->new( name => $self->name);
    return $obj->calc_digest($fh, $blksize);
}

sub _get_hash_string_async {
    my ($self, $fh, $blksize) = @_;
    my $result;
    if ($self->has_async_support()) {
        my $class = 'Archive::BagIt::Role::OpenSSL::Async';
        load_class($class) or croak("could not load class $class");
        my $obj = $class->new(name => $self->name);
        $result = $obj->calc_digest($fh, $blksize);
    } else {
        $result = $self->_get_hash_string_sync($fh, $blksize);
    }
    return $result;
}


sub get_hash_string {
    my ($self, $fh) = @_;
    my $blksize = $self->get_optimal_bufsize($fh);
    my $bagobj = $self->bagit;
    if ($bagobj->use_async) {
        return $self->_get_hash_string_async($fh, $blksize);
    }
    return $self->_get_hash_string_sync($fh, $blksize);
}


no Moo;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Archive::BagIt::Role::OpenSSL - A role that handles plugin loading

=head1 VERSION

version 0.091

=head2 has_async_support()

returns true if async IO is possible, because IO::Async could be loaded, otherwise returns false

=head2 get_hash_string($fh)

calls synchronous or asynchronous function to calc digest of file, depending on result of $bag->use_async()
returns the digest result as hex string

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<https://metacpan.org/module/Archive::BagIt/>.

=head1 BUGS AND LIMITATIONS

You can make new bug reports, and view existing ones, through the
web interface at L<http://rt.cpan.org>.

=head1 AUTHOR

Andreas Romeyke <cpan@andreas.romeyke.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Rob Schmidt <rjeschmi@gmail.com>, William Wueppelmann and Andreas Romeyke.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
