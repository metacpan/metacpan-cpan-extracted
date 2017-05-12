# ============================================================================
package CatalystX::I18N::TypeConstraints;
# ============================================================================

use strict;
use warnings;

use Moose::Util::TypeConstraints;
use DateTime::TimeZone;
use DateTime::Locale;
use MooseX::Types::Path::Class;

our $LOCALE_RE = qr/^([a-z]{2,3})(?:_([A-Z]{2}))?$/;
our $LANGUAGE_RE = qr/^[a-z]{2,3}$/;

subtype 'CatalystX::I18N::Type::Territory'
    => as 'Str'
    => where { m/^[A-Z]{2}$/ };

subtype 'CatalystX::I18N::Type::Locale'
    => as 'Str'
    => where { $_ =~ $LOCALE_RE };

subtype 'CatalystX::I18N::Type::Language'
    => as 'Str'
    => where { $_ =~ $LANGUAGE_RE };

subtype 'CatalystX::I18N::Type::Locales'
    => as 'ArrayRef[CatalystX::I18N::Type::Locale]';

coerce  'CatalystX::I18N::Type::Locales'
    => from 'Str'
    => via { return [ $_ ] };

subtype 'CatalystX::I18N::Type::DirList'
    => as 'ArrayRef[Path::Class::Dir]';
    
coerce 'CatalystX::I18N::Type::DirList'
    => from 'Path::Class::Dir'
    => via { 
        [ $_ ]
    }
    => from 'Str'
    => via { 
        [ Path::Class::Dir->new($_) ]
    }
    => from 'ArrayRef[Str]'
    => via { 
        [ 
            map { Path::Class::Dir->new($_) } @{$_}
        ]
    };

subtype 'CatalystX::I18N::Type::MaketextHandle'
    => as duck_type([qw(maketext)]);

no Moose::Util::TypeConstraints;

1;

=encoding utf8

=head1 NAME

CatalystX::I18N::TypeConstraints - I18N Moose type constraints

=head1 SYNOPSIS

 use Moose;
 use CatalystX::I18N::TypeConstraints;
 
 has 'locale' => (
    is      => 'rw',
    isa     => 'CatalystX::I18N::Type::Locale',
 );

=head1 TYPE CONSTRAINTS

=over

=item * CatalystX::I18N::Type::Territory

=item * CatalystX::I18N::Type::Locale

=item * CatalystX::I18N::Type::Language

=item * CatalystX::I18N::Type::MaketextHandle

=item * CatalystX::I18N::Type::DirList

=back

=head1 AUTHOR

    Maroš Kollár
    CPAN ID: MAROS
    maros [at] k-1.com
    
    L<http://www.k-1.com>