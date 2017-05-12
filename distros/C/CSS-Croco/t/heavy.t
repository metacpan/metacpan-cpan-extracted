#
#===============================================================================
#
#         FILE:  heavy.t
#
#  DESCRIPTION:
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Andrey Kostenko (), <andrey@kostenko.name>
#      COMPANY:  Rambler Internet Holding
#      VERSION:  1.0
#      CREATED:  06.11.2009 17:17:49 MSK
#     REVISION:  ---
#===============================================================================

use strict;
use warnings;

use Test::More qw(no_plan);    # last test to print

use CSS::Croco;
my $parser = CSS::Croco->new;
foreach my $file ( glob 't/data/*' ) {
    my $sheet = $parser->parse_file($file);
    ( my $result_file = $file ) =~ s/data/parsed/;
    ok $sheet, 'stylesheet parsing';
    foreach my $rule ( $sheet->rules ) {
        ok $rule, 'rule parsing';
        if ( ref $rule eq 'CSS::Croco::Statement::RuleSet' ) {
            parse_selectors($rule);
        } elsif ( ref $rule eq 'CSS::Croco::Statement::Media' ) {
            ok $rule->media_list;
            foreach my $subrule ( $rule->rules ) {
                parse_selectors($subrule);
            }
        }
    }
    if ( -e $result_file ) {
        open +( my $result ), '<', $result_file;
        TODO: {
            local $TODO = "Wating for libcroco developers";
            is $sheet->to_string, ( join '', <$result> );
            close $result;
        }
    }
    else {
        open +( my $result ), '>', $result_file or die $!;
        print $result $sheet->to_string;
        close $result;
    }
}

sub parse_selectors {
    my $rule = shift;
    foreach my $selector ( $rule->selectors ) {
        ok $selector;
    }
    foreach my $declaration ( $rule->declarations ) {
        ok $declaration;
        ok defined $declaration->value;
        ok defined $declaration->value->get;
    }
}
