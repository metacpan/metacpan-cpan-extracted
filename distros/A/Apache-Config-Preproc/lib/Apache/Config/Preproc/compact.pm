package Apache::Config::Preproc::compact;
use strict;
use warnings;
use Carp;

our $VERSION = '1.02';

sub new {
    croak "too many arguments" unless @_ == 2;
    bless {}, shift
}

sub expand {
    my ($self, $d, $repl) = @_;
    return $d->type eq 'blank' || $d->type eq 'comment';
}

1;

__END__

=head1 NAME    

Apache::Config::Preproc::compact - remove empty lines and comments

=head1 SYNOPSIS

    $x = new Apache::Config::Preproc '/path/to/httpd.conf',
                -expand => [ qw(compact) ]; 

=head1 DESCRIPTION

Removes empty and comment lines from the Apache configuration parse
tree.

=cut    
