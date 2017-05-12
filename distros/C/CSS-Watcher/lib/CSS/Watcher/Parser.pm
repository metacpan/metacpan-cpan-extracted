package CSS::Watcher::Parser;

use strict; 
use warnings;

use Carp;
use Log::Log4perl qw(:easy);
use CSS::Selector::Parser qw/parse_selector/;

my $nested;                     # regexp for "{ }"
$nested = qr/
                \{
                (
                    [^{}]
                |
                    (??{ $nested })
                )*
                \}
            /x;

sub new {
    my $class = shift;
    return bless ({}, $class);
}

sub parse_css {
    my $self = shift;
    my $source = shift;

    my %classes;
    my %ids;

    $self->_parse_css($source, \%classes, \%ids);
    
    return (\%classes, \%ids);
}

sub _parse_css {
    my $self = shift;
    my ($source, $classes, $ids) = @_;

    $source =~s|/\*.*?\*/||gs;      # remove comments

    while ($source =~ m/(.*?)($nested)/gs) {
        my ($selector, $selector_body) = ($1, $2);

        if ($selector =~/\s*\@media/s) {
            if ($selector_body =~m /\{(.+)\}/s) {
                $self->_parse_css($1, $classes, $ids);
            }
            next;
        } elsif ($selector =~/\s*\@/s) {
            # ignore @keyframes, etc @..
            next;
        }
        eval {
            foreach (parse_selector($selector)) {
                next unless (ref $_ eq 'ARRAY');
                foreach my $rule (@{$_}) {
                    if (exists $rule->{class}) {
                        # Bug, selector for .foo.bar return class foo.bar
                        # so split this selector by "."
                        foreach my $classname (split /\./, $rule->{class}) {
                            $classes->{
                                exists ($rule->{element}) ? $rule->{element} : "global"
                            }{ $classname }++;
                        }
                    }
                    if (exists $rule->{id}) {
                        $ids->{
                            exists ($rule->{element}) ? $rule->{element} : "global"
                        }{ $rule->{id} }++;
                    }
                } 
            }
        };
        if ($@) {
            # log selector parse failure
            ERROR "Can't parse selector: \"$selector\"";
        }
    }
}


1;

__END__

=head1 NAME

CSS::Watcher::Parser - Extract classes, ids from css

=head1 SYNOPSIS

   use CSS::Watcher::Parser;
   my $parser = CSS::Watcher::Parser->new()
   my ($hclasses, $hids) = parser->parse_css ('.foo, #myid {color: red}');

=head1 DESCRIPTION

Simple parser of css files

=head1 AUTHOR

Olexandr Sydorchuk (olexandr.syd@gmail.com)

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Olexandr Sydorchuk

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=cut
