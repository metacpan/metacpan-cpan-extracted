package App::Ikaros::Helper;
use strict;
use warnings;
use Getopt::Long;
use YAML::XS qw/LoadFile/;
use base 'Exporter';

our @EXPORT_OK = qw/
    option_parser
    include_blacklist
    exclude_blacklist
    load_from_yaml
    uniq
/;

sub option_parser {
    my ($options) = @_;
    local @ARGV = @ARGV;
    my $parser = Getopt::Long::Parser->new(
        config => ["no_ignore_case", "pass_through"],
    );
    my %results;
    my @opt_list;
    my @opts = map {
        my ($opt_name) = $_ =~ /([0-9a-zA-Z-_]+)=?/;
        [$_, $opt_name];
    } @$options;
    push @opt_list, $_->[0] => \$results{$_->[1]} foreach @opts;
    $parser->getoptions(@opt_list);
    return \%results;
}

sub include_blacklist {
    my ($all_tests, $blacklist) = @_;
    my %tests;
    $tests{$_}++ foreach @$blacklist;
    return [ grep { exists $tests{$_} } @$all_tests ];
}

sub exclude_blacklist {
    my ($all_tests, $blacklist) = @_;
    my %tests;
    $tests{$_}++ foreach @$blacklist;
    return [ grep { not exists $tests{$_} } @$all_tests ];
}

sub load_from_yaml {
    my ($filename) = @_;
    return LoadFile $filename;
}

sub uniq($) {
    my ($array) = shift;
    my %uniq;
    $uniq{$_}++ foreach @$array;
    return [ keys %uniq ];
}

1;
