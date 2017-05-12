package Bone::Easy;

use strict;
require Exporter;

use Bone::Easy::Rules;

use vars qw($VERSION %Rules @EXPORT @ISA $Rules_Fh $Start_Kind);
$VERSION = '0.04';
@ISA = qw(Exporter);
@EXPORT = qw(pickup);

$Rules_Fh = *Bone::Easy::Rules::DATA;
load_rules();

sub load_rules {
    while(my $rule = <$Rules_Fh>) {
        next unless $rule =~ /\S+/;

        chomp $rule;
        $rule =~ s/\s+$//;

        my($kind, $text) = $rule =~ /^(.*)-->(.*)$/;
        push @{$Rules{$kind}}, $text;
    }
}

$Start_Kind = 'REMARK';
sub pickup {
    my $line = ${$Rules{$Start_Kind}}[rand @{$Rules{$Start_Kind}}];

    return ucfirst replace($line);
}

sub replace {
    my $line = shift;
    
    $line =~ s{(\b[A-Z]{2,}\b)}
              {
                  exists $Rules{$1} 
                    ? replace(${$Rules{$1}}[rand @{$Rules{$1}}])
                    : $1
              }eg;

    return $line;
}


=pod

=head1 NAME

Bone::Easy - Perl module for generating pickup lines.

=head1 SYNOPSIS

  use Bone::Easy;

  # I know you get this a lot, but what's a unholy fairy like you 
  # doing in a mosque like this?
  print pickup, "\n";

=head1 DESCRIPTION

Generates pickup-lines GUARANTEED to get something thrown in your face.


=head1 AUTHOR

Idea and original ruleset by TheSpark.com <http://www.thespark.com>
and Chris Coyne <ccoyne@staff.thespark.com>

Perl Code by Michael G Schwern <schwern@pobox.com>


=head1 LICENSE

This program may be distributed under the same license as Perl itself,
except for Bone::Easy::Rules.  L<Bone::Easy::Rules> for details.


=head1 SEE ALSO

L<Safe>, L<Sex>, L<pickup>, L<Bone::Easy::Rules>

=cut


1;
