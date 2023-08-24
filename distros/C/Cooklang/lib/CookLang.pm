package CookLang;
$CookLang::VERSION = '0.12';
use Object::Pad qw( :experimental(init_expr) );
use strict;
use warnings;

use Number::Fraction;

class Cooking {
use experimental qw(try);
    field $qty: param ||= undef;
    method finite {
        my $den = shift;
        return !! ( ! ( $den % 2 ) || ! ( $den % 5 ));
    };
    method qty {
        if (! defined $qty ) {
            return $self->isa( 'Cookware' ) ? '' : 1;
        }
        try {
            my $fraction = Number::Fraction->new( $qty );
            return $self->finite( $fraction->{den} ) ?
                $fraction->to_num :
                $fraction->to_string
            ;
        } catch ($e) {
            return $qty;
        }
    };
}

class Step {
    field $line :param;
    field @element;
    field $final = 0;
    method add_element( $element, $pos, $length ) {
        push @element, Element->new( start => $pos, length => $length , element => $element);
    };
    method finalize {
        return if $final;

        $final = 1;
        my $startpos = 0;
        my @new;
        for my $elm ( @element ) {
            my $pos = $elm->start;
            my $length = $elm->length;
            push @new, Element->new(
                element => substr( $line, $startpos, $pos - $startpos ),
                start => $startpos,
                length => $length
            ) if $startpos < $pos;

            push @new, $elm if ref $elm->element ne 'Comment';
            $startpos = $pos + $length;
        }
        my $length = length( $line ) - $startpos;
        push @new, Element->new(
            element => substr( $line, $startpos ),
            start => $startpos,
            length => $length
        ) if $length > 0;

        @element = @new;
    };
    method ast {
        $self->finalize;
        return [
            map { $_->ast } @element,
        ];
    };
}

class Element {
    field $element :reader param;
    field $start :reader param = 1;
    field $length :reader param = '';
    method ast {
        return ! ref $element ? {
            type => 'text',
            value => $element,
        } : $element->ast;
    };
}

class Ingredient :isa( Cooking ) {
    field $name :param;
    field $unit: param = '';

    method ast {
        return {
            type => 'ingredient',
            name => $name,
            quantity => $self->qty,
            units => $unit,
        };
    };
}

class Metadata {
    field $key :param;
    field $value :param;
    method ast {
        return $key => $value;
    };
}

class Comment {
    field $comment :param;
    method ast {
        return {
            type => 'comment',
            comment => $comment,
        };
    };
}

class Cookware :isa( Cooking ) {
    field $name :param;
    method ast {
        return {
            type => 'cookware',
            name => $name,
            quantity => $self->qty,
        };
    };
}

class Timer :isa( Cooking ) {
    field $name :param;
    field $unit: param = '';
    method ast {
        return {
            type => 'timer',
            name => $name,
            quantity => $self->qty,
            units => $unit,
        };
    };
}

class Recipe {
    field @step;
    field @ingredient;
    field @comment;
    field @cookware;
    field @timer;
    field @metadata;
    BUILD ( $text ) {
        # Regexes
        my $quantity_regex = qr/(?:{\s*(?<qty>[^%]*?)\s*%\s*(?<unit>[^%]+?)\s*}|{\s*(?<qty>.*?)\s*})/;
        my $comment_regex = qr/--(.*)|\[-((.|\n)+?)-\]/;
        my $ingredient_regex = qr/(@(?:(?<name>[^@#~]+?)${quantity_regex})|@(?<name>(?:[^@#~\s]+)))/;
        my $cookware_regex = qr/(#(?:(?<name>[^@#~]+?)${quantity_regex})|#((?:(?<name>[^@#~\s]+))))/;
        my $timer_regex = qr/(~([^@#~]*)${quantity_regex})/;
        my $metadata_regex = qr/^>>\s*(.*?)\s*:\s*(.*)$/;

        # Trim white space, possibly remove empty lines
        my @lines = map { s/^\s+|\s+$//r } split "\n", $text;
        for my $line ( @lines ) {
            my $step = Step->new( line => $line );
            my $pos = 0;
            next unless $line;

            if ( $line =~ m/$metadata_regex/ ) {
                my $metadata = Metadata->new( key => $1, value => $2 );
                push @metadata, $metadata;
                next;
            }
            while ( $line =~ m/$ingredient_regex/g ) {
                # warn join '-', $+{name}, $+{qty}, $+{unit};
                # my $ingredient = [ $1, $2 // $4, $3, length( $1 ), pos( $line ) ];
                my $ingredient = Ingredient->new( %+ );
                my $length = length( $1 );
                my $pos = pos( $line ) - $length;
                push @ingredient, $ingredient;
                $step->add_element( $ingredient, $pos, $length );
            }
            while ( $line =~ m/$cookware_regex/g ) {
                my $cookware = Cookware->new( %+ );
                my $length = length( $1 );
                my $pos = pos( $line ) - $length;
                push @cookware, $cookware;
                $step->add_element( $cookware, $pos, $length );
            }
            while ( $line =~ m/$timer_regex/g ) {
                my $timer = Timer->new( name => $2, qty => $3, unit => $4 );
                my $length = length( $1 );
                my $pos = pos( $line ) - $length;
                push @timer, $timer;
                $step->add_element( $timer, $pos, $length );
            }
            while ( $line =~ m/$comment_regex/g ) {
                my $txt = $1 // $2;
                my $length = length( $txt ) + 2;
                my $pos = pos( $line ) - $length;
                my $comment = Comment->new( comment => $txt );
                push @comment, $comment;
                $step->add_element( $comment, $pos, $length );
            }
            $step->finalize;
            push @step, $step;
        }
    }
    method ast {
        return {
            metadata => { map { $_->ast } @metadata },
            comment => [ map { $_->ast } @comment ],
            ingredients => [ map { $_->ast } @ingredient ],
            cookware => [ map { $_->ast } @cookware ],
            timer => [ map { $_->ast } @timer ],
            steps => [ grep { @$_ } map { $_->ast } grep { $_ } @step ],
        };
    };
}

# ABSTRACT: Perl Cooklang parser
# COPYRIGHT

__END__

=pod

=encoding UTF-8

=head1 NAME

CookLang - Perl Cooklang parser

=head1 VERSION

version 0.12

=head1 SYNOPSIS

    my $source = <some Cooklang text>;
    my $recipe = Recipe->new( $source );
    my $ast = $recipe->ast;
    ...

=head1 DESCRIPTION

For the Cooklang syntax, see [Cooklang](https://cooklang.org/).

=head1 NAME

Cooklang - Perl Cooklang parser

=head1 AVAILABILITY

Cooklang is implemented using Object classes as defined in Object::Pad which seems to require Perl 5.26

=head1 COMMUNITY

- [Code repository, Wiki and Issue Tracker](https://gitlab.com/perl5182717/CookLang)
- [CPAN](https://metacpan.org/pod/CookLang)

=head1 BUGS

Please report any bugs or feature requests to bug-role-rest-client at rt.cpan.org, or through the
web interface at http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Cooklang.

=head1 AUTHOR

Kaare Rasmussen <kaare at cpan dot org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Kaare Rasmussen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
