package App::ForExample::ModuleEmbedCatalog;

use strict;
use warnings;

{
    my $catalog;
    sub extract {
        my $self = shift;
        my $module = shift;
        my $end = shift;

        $end = '__ASSET__' unless defined $end;
        $end = qr/^\Q$end\E$/ unless ref $end eq 'Regexp';

        my $handle = "${module}::DATA";

        return $catalog ||= do {
            my %catalog;
            my ($path, $content);
            while (<$handle>) {
                if ( ! $path ) {
                    next unless m/\S/;
                    chomp; $path = $_;
                    $content = '';
                }
                elsif ( $_ =~ $end ) {
                    my $__ = $content;                                 
                    $catalog{$path} = \$__;                            
                    undef $path;                                       
                    undef $content;                                    
                }
                else {                                                 
                    $content .= $_;                                    
                }
            }
            \%catalog;
        };
    }     
}

1;
