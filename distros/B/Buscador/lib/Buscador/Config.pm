package Buscador::Config;
use strict;
use vars qw(%config);

use Apache;
use Carp qw(croak);
use Cwd;




BEGIN {

    my $home;

    # h-h-h-ack!
    eval {
        my $r = Apache->request;

        $home = $r->document_root.$r->location;
    };

    if ($@) {
        $home = getcwd();    
    }


    chdir $home;

    $config{home} = $home;

    open (CONF, "buscador.config") || die "Can't open config file: $!\n";
    while (<CONF>) {
        chomp;
        next if /^\s*#/;
        next if /^\s*$/;
        s!(^\s*|\s*$)!!;
        my ($key, $val) = split /\s*=\s*/, $_, 2;
        $config{$key} = $val;
    }

    close CONF;
}


sub AUTOLOAD {
   our ($AUTOLOAD);
   no strict 'refs';
   my $tag = $AUTOLOAD;
   $tag =~s/.*:://;

   my $joined = join ",", keys %config;
   croak "No such method $tag try one of $joined" unless $config{$tag};

   *$AUTOLOAD = sub {
        my $self = shift;
        if (@_) {
            my $val  = shift;
            $config{$tag} = $val;
            return $val;
        }
        return $config{$tag};
   };

   goto &$AUTOLOAD;


}

1; 

__END__

=head1 NAME

Buscador::Config - provide config values

=head1 SYNPOSIS

    use Buscador::Config;

    print Buscador::Config->dsn;

=head1 DESCRIPTION

This works out the current directory (dependent on whether 
the module is working under Apache or not), reads in a 
C<buscador.config> file and turns every C<key=value> pair
into a subroutine C<Buscador::Config->key>.

=head1 AUTHOR

Simon Wistow, <simon@thegestalt.org>

=head1 COPYRIGHT

Copyright 2004, Simon Wistow

=cut





