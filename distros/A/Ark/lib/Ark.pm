package Ark;
use 5.008001;
use Mouse 1.00;
use Mouse::Exporter;

use Ark::Core;

our $VERSION = '1.22';

do {
    my %EXPORTS;

    sub import {
        my ($class, @bases) = @_;

        my $caller = caller;

        require utf8; import utf8;

        my @super;
        push @bases, 'Core' unless @bases;
        for my $base (@bases) {
            my $pkg;
            if ($base =~ /^\+/) {
                ($pkg = $base) =~ s/^\+//;
            } else {
                $pkg = "Ark::${base}";
            }
            push @super, $pkg;
            Ark::Core->ensure_class_loaded($pkg);

            no strict 'refs';
            for my $keyword (@{ $pkg . '::EXPORT' }) {
                push @{ $EXPORTS{$caller} }, $keyword;
                *{ $class . '::' . $keyword } = *{ $pkg . '::' . $keyword };
            }

            if (my $exporter = $pkg->can('EXPORT')) {
                $exporter->($pkg, $caller);
            }
        }

        Mouse::Meta::Class->initialize($caller);

        my ($import, $unimport) = Mouse::Exporter->build_import_methods(
            exporting_package => $caller,
            also => "Mouse",
        );

        $caller->$import({ into => $caller });
        $caller->meta->superclasses(@super);

        push @{ $EXPORTS{$class} }, $unimport;
    }

    sub unimport {
        my $caller  = caller;

        for my $item (@{ $EXPORTS{$caller} || [] }) {
            if (ref $item eq 'CODE') {
                $caller->$item;
            }
            else {
                no strict 'refs';
                delete ${ $caller . '::' }{ $item };
            }
        }
    }
};

1;
__END__

=head1 NAME

Ark - light weight Catalyst-ish web application framework

=head1 SYNOPSIS

    use Ark;

=head1 DESCRIPTION

Ark is light weight Catalyst-ish web application framework.

=head1 LICENSE

Copyright (C) Daisuke Murase.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Daisuke Murase <typester@cpan.org>

=cut
