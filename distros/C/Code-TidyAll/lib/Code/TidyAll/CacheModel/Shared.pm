package Code::TidyAll::CacheModel::Shared;

use strict;
use warnings;

use Moo;

extends 'Code::TidyAll::CacheModel';

our $VERSION = '0.78';

sub _build_cache_key {
    my $self = shift;
    return $self->_sig(
        [
            $self->SUPER::_build_cache_key,
            $self->file_contents
        ]
    );
}

sub _build_cache_value {
    return 1;
}

sub remove {
    return;
}

1;

# ABSTRACT: Shared cache model for Code::TidyAll

__END__

=pod

=encoding UTF-8

=head1 NAME

Code::TidyAll::CacheModel::Shared - Shared cache model for Code::TidyAll

=head1 VERSION

version 0.78

=head1 SYNOPSIS

   my $cta = Code::TidyAll->new(
       cache_model_class => 'Code::TidyAll::CacheModel::Shared',
       ...
   );

=head1 DESCRIPTION

An alternative caching model for Code::TidyAll designed to work in shared build
systems / systems with lots of branches.

This cache model uses both the file name and file contents to build the cache
key and a meaningless cache value. It does not care about the modification time
of the file.

This allows you to share a cache when you might have several versions of a file
that you switch backwards and forwards between (e.g. when you're working on
several branches) and keep the cache values

=head1 SUPPORT

Bugs may be submitted at
L<https://github.com/houseabsolute/perl-code-tidyall/issues>.

I am also usually active on IRC as 'autarch' on C<irc://irc.perl.org>.

=head1 SOURCE

The source code repository for Code-TidyAll can be found at
L<https://github.com/houseabsolute/perl-code-tidyall>.

=head1 AUTHORS

=over 4

=item *

Jonathan Swartz <swartz@pobox.com>

=item *

Dave Rolsky <autarch@urth.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 - 2020 by Jonathan Swartz.

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.

The full text of the license can be found in the F<LICENSE> file included with
this distribution.

=cut
