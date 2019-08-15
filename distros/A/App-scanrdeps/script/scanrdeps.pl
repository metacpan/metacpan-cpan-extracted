#!/usr/bin/env perl

use Getopt::Long::Descriptive;
use Module::Metadata;
use File::Basename;
use List::Util qw/uniq first/;
use Term::ANSIColor;
use feature 'say';

=encoding utf-8

=head1 NAME

scanrdeps.pl - find all reverse dependencies deeply using grep

=head1 SYNOPSIS

    scanrdeps.pl site::Import::Proto
    scanrdeps.pl -e pl,thtml -c -p /220v/220V site::Import::Proto

=head1 DESCRIPTION

scanrdeps.pl is static code analysis tool, it scans for reverse dependencies

Requires grep with -r -E and --include options

Typical use case: you want to find all perl scripts that are using particular database/table. 
You found module with database connection and then scan for reverse dependencies by this module

scanrdeps.pl uses regex which correnctly process use and use parent

Another use case: you want to get list of files which are affected by particular module

=head1 AUTHOR

Pavel Serikov E<lt>pavelsr@cpan.orgE<gt>

=cut



my ( $opts, $usage ) = describe_options(
    '%c %o <package>',
    [ '<package> is package name like site::Import::Proto' ],
    [ 'extensions|e=s', "Print only particular extensions. By default it's {pm,pl,thtml}", { default  => 'pm,pl,thtml' } ],
    [ 'path|p=s', "Path, default is current", { default  => '.' } ],
    [ 'chain|c', "Show chain, how each result gotten. -> in output means use", { default  => 0 } ],
    [ 'depth|d=i', "Max scan depth, by default is 10", { default  => 10 } ],
    [ 'verbose|v', "print extra stuff" ],
    [ 'help|h', "print usage message and exit", { shortcircuit => 1 } ],
);

print( $usage->text ), exit if $opts->help;
my $module = $ARGV[0];

if (!defined $module) {
    print( "Exit. No <package> specified\n\n".$usage->text );
    exit;
}

my $lvl = 0;

my @result;
my @last_scan_result = ( 'some' );
my @modules_for_next_check = ( $module );
say 'Scanning module '.colored($module, 'on_magenta').' for reverse dependencies' if $opts->verbose;

while ( @last_scan_result && ( $lvl <= $opts->depth ) ) { 
# !is_all_final(@last_scan_result)
    
    if ($lvl >= $opts->depth) {
        print( "Max depth (".$opts->depth.") is reached\n" );
        exit;
    }
    
    @last_scan_result = get_rdeps(@modules_for_next_check);
    
    if (@last_scan_result) {
        $_->{'level'} = $lvl for @last_scan_result;
        push @result, @last_scan_result;
        
        @modules_for_next_check = map { $_->{package} } grep { $_->{package} ne 'main' } @last_scan_result;
        @modules_for_next_check = grep { !in_array( [ map { $_->{search_by} } @result ], $_ ) } @modules_for_next_check;
        @modules_for_next_check = uniq @modules_for_next_check;
        
        say colored("== Level : ".$lvl.", reverse dependencies: ".scalar @last_scan_result.", modules ".scalar @modules_for_next_check, 'green') if $opts->verbose;
        if (@modules_for_next_check) {
            say "Modules :" if $opts->verbose;
            for my $m (@modules_for_next_check) {
                my @use = map { $_->{search_by} } grep { $_->{package} eq $m } @last_scan_result;
                say $m. colored(' -> '.join(', ', @use ), 'yellow') if $opts->verbose;
            }
        }
    }
    
    $lvl++;    
}

print_result(@result);

sub filter_by_extension {
    my ($path, @suffixes) = @_;
    my ($name,$path,$suffix) = fileparse($path,@suffixes);
    return 1 if $suffix;
    return 0;
}

sub get_chain {
    my ( $node, @res ) = @_;
    
    my $key = 'search_by';
    # my $key = 'match_str'; # TO-DO
    
    my $level   = $node->{level};
    my $package = $node->{$key};

    my @chain;
    for ( my $i = $level-1 ; $i >= 0 ; $i-- ) {
        my $next_node = first { $_->{level} eq $i && $_->{package} eq $package } @res;
        $package = $next_node->{$key};
        push @chain, $package;
    }
    return @chain;
}


sub print_result {
    my (@result) = @_;
    my @extensions = split(',',$opts->extensions);
    say 'Show only files with extensions: '.colored( join(',',@extensions), 'on_magenta' ) if $opts->verbose;
    
    for (@result) {
        $_->{chain} = join( ' -> ', get_chain($_, @result) );
    }
    
    my @result = grep { filter_by_extension($_->{file}, @extensions) } @result;
        
    for my $r (@result) {
        my $str = '';
        $str.= colored($r->{file}, 'red');
        $str.= " ".$r->{chain} if ($opts->chain);
        print $str."\n";
    };

}

# by list
sub get_rdeps {
    my (@packages) = @_;
    my @res;
    for my $p (@packages) {
        #warn "get_rdeps() ".$p;
        push @res, get_rdeps_by_module($p);
    }
    return @res;
}

# by one
sub get_rdeps_by_module {
    my ($module) = @_;
    my $cmd = 'grep -r -E "use*.+' . $module . '" --include=\*.pm --include=\*.pl --include=\*.thtml '.$opts->path;
    my @output = split( "\n", `$cmd` );
    my @chain;
    for (@output) {
        my @tmp = split( /(?<!:):(?!:)/, $_ );
        push @chain, { 
            'file' => $tmp[0], 
            'match_str' => $tmp[1], 
            'package' => Module::Metadata->new_from_file( $tmp[0] )->name,
            'search_by' => $module 
        };
    }
    return @chain;
}

# Check if level array is all ending
sub is_all_final {
    my (@arr) = @_;
    return 0 if (@arr == 0);
    return 1 if ( scalar @arr == scalar grep { $_->{module} eq 'main' } @arr );
    return 0;
}

sub in_array {
    my ( $array_ref, $pattern ) = @_;
    no if ( $] >= 5.018 ), warnings => 'experimental';
    $array_ref //= [];
    return $pattern ~~ @{$array_ref};
}