package Datahub::Factory::Fixer::Fix;

use Datahub::Factory::Sane;

our $VERSION = '1.72';

use Moo;
use Catmandu;
use namespace::clean;

has file_name     => (is => 'ro', required => 1, isa => sub {
    if (!defined($_[0])) {
        Catmandu::BadArg->throw(
            message => 'Required argument "file_name" undefined'
        );
    }
 });

with 'Datahub::Factory::Fixer';

sub _build_fixer {
    my $self = shift;
    my $fixer;
    $fixer = Catmandu->fixer($self->file_name);
    return $fixer;
}

1;
__END__

=encoding utf-8

=head1 NAME

Datahub::Factory::Fixer::Fix - Execute fixes on a single record

=head1 SYNOPSIS

    use Datahub::Factory;

    my $fix_options = {
        file_name => '/tmp/my.fix'
    }

    my $fixer = Datahub::Factory->fixer('Fix')->new($fix_options);

    $fixer->fixer->fix({'id' => 1});

=head1 DESCRIPTION

This module executes the fixes in C<file_name> for a single record.

=head1 PARAMETERS

=over

=item C<file_name>

Location of the fix file.

=back

=head1 ATTRIBUTES

=over

=item C<fixer>

A L<Fixer|Catmandu::Fix> that can be used in your script.

=back

=head1 AUTHORS

Pieter De Praetere <pieter@packed.be>

Matthias Vandermaesen <matthias.vandermaesen@vlaamsekunstcollectie.be>

=head1 COPYRIGHT

Copyright 2017 - PACKED vzw, Vlaamse Kunstcollectie vzw

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the terms of the GPLv3.

=cut
