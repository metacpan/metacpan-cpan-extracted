package DJabberd::Authen::UserLimit;
use strict;
use base 'DJabberd::Authen';
use DJabberd::Log;
our $logger = DJabberd::Log->get_logger;

use vars qw($VERSION);
$VERSION = '0.30';


use DJabberd::Util qw(as_num);
sub log {
    $logger;
}

sub set_config_userlimit {
    my ($self, $val) = @_;
    $self->{limit} = as_num($val);
}

sub finalize {
    my ($self) = @_;
    die "Missing UserLimit directive" if not $self->{limit};
}


sub check_cleartext {
         my ($self, $cb, %args) = @_;
         # args contain: username and conn
         my $conn = $args{conn};
         my $nb_user = keys %{$conn->vhost->{jid2sock}};
         my $limit = $self->{limit};
         $logger->info("Number of user : $nb_user , limit : $limit ");
         if ($nb_user ge $limit) {
            $cb->reject;
            return;
         };
         $cb->decline;
}

1;

__END__

=head1 NAME

DJabberd::Authen::UserLimit - limit the number of connected user

=head1 SYNOPSIS

 <Vhost example.com>
     ...
         <Plugin DJabberd::Authen::UserLimit>
                UserLimit 150
         </Plugin>
     ...
 </VHost>

=head1 DESCRIPTION

This limit the number of concurent users, for the whole vhost, to not 
bring your server down in case of mass subscription. This kind of protective 
measure can be found in the apache http server, for example. 

=head1 COPYRIGHT

This module is Copyright (c) 2006 Michael Scherer
All rights reserved.

You may distribute under the terms of either the GNU General Public
License or the Artistic License, as specified in the Perl README file.

=head1 LIMITATIONS

This module do not work with other modules that use get_password, or
check_digest, but the later will be supported in the futur.

=head1 WARRANTY

This is free software. IT COMES WITHOUT WARRANTY OF ANY KIND.

=head1 AUTHORS

Michael Scherer <misc@zarb.org>
