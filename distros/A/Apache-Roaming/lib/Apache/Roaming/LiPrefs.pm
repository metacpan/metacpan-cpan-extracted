# -*- perl -*-
#
#   $Id: LiPrefs.pm,v 1.2 1999/04/23 15:29:47 joe Exp $
#
#
#   Apache::Roaming - A mod_perl handler for Roaming Profiles
#
#
#   Based on mod_roaming by
#	Vincent Partington <vincentp@xs4all.nl>
#	See http://www.xs4all.nl/~vincentp/software/mod_roaming.html
#
#
#   Copyright (C) 1999    Jochen Wiedmann
#                         Am Eisteich 9
#                         72555 Metzingen
#                         Germany
#
#                         Phone: +49 7123 14887
#                         Email: joe@ispsoft.de
#
#   All rights reserved.
#
#   You may distribute this module under the terms of either
#   the GNU General Public License or the Artistic License, as
#   specified in the Perl README file.
#
############################################################################

require 5.004;
use strict;


use Apache::Roaming ();
use Apache::File ();


package Apache::Roaming::LiPrefs;

$Apache::Roaming::LiPrefs::VERSION = '0.1002';
@Apache::Roaming::LiPrefs::ISA = qw(Apache::Roaming);


=pod

=head1 NAME

    Apache::Roaming::LiPrefs - A roaming handler for modifying Netscape
	Preferences


=head1 SYNOPSIS

      # Configuration in httpd.conf or srm.conf
      # Assuming DocumentRoot /home/httpd/html

      PerlModule Apache::Roaming
      <Location /roaming>
        PerlHandler Apache::Roaming::LiPrefs->handler
        PerlTypeHandler Apache::Roaming::LiPrefs->handler_type
        AuthType Basic
        AuthName "Roaming User"
        AuthUserFile /home/httpd/.htusers
        require valid-user
        PerlSetVar BaseDir /home/httpd/html/roaming
	PerlSetVar LiPrefsConfigFile /home/httpd/liprefs.cnf
      </Location>

  In theory any AuthType and require statement should be possible
  as long as the $r->connection()->user() method returns something
  non trivial.


=head1 DESCRIPTION

This is a subclass of Apache::Roaming that allows you to overwrite
certain Netscape settings of your users, both initial and/or
permanent. The idea is to overwrite the web servers GET method
for parsing and modifying the users liprefs files.

Liprefs files are a collection of lines in the format

    user_pref("varname", value);

In other words, they are obviously close to hash arrays. Thus the
module configuration is read from two hash arrays:

=over 8

=item %Apache::Roaming::LiPrefs::INITIAL

If any of the given hash keys is missing in the liprefs file, then a
corresponding line will be added to the liprefs file.

=item %Apache::Roaming::LiPrefs::ALWAYS

Lines corresponding to one of the given hash keys will be silently
replaced by the given values. If no corresponding line is found,
the hash key will be treated like it where part of the I<INITIAL>
hash.

=back

An example might help. Suggest the following arrays:

  %Apache::Roaming::LiPrefs::INITIAL = {
    'security.email_as_ftp_password' => 'true',
    'mail.remember_password' => 'false'
  };
  %Apache::Roaming::LiPrefs::ALWAYS = {
    'network.hosts.pop_server' => 'pop.cmo.de',
    'network.hosts.smtp_server' => 'smtp.cmo.de'
  }

If the users saved liprefs file is

  user_pref("network.hosts.pop_server", "pop.company.com");
  user_pref("mail.remember_password", true);

Then the module will change it to

  user_pref("network.hosts.pop_server", "pop.cmo.de");
  user_pref("network.hosts.smtp_server", "smtp.cmo.de");
  user_pref("mail.remember_password", true);
  user_pref("security.email_as_ftp_password", true);


=head1 INSTALLATION

Follow the instructions for installing the Apache::Roaming module.
See L<Apache::Roaming(3)>. The only difference is that you use
Apache::Roaming::LiPrefs rather than its superclass Apache::Roaming:

    PerlModule Apache::Roaming::LiPrefs
    <Location /roaming>
      PerlHandler Apache::Roaming::LiPrefs->handler
      PerlTypeHandler Apache::Roaming::LiPrefs->handler_type
      AuthType Basic
      AuthName "Roaming User"
      AuthUserFile /home/httpd/.htusers
      require valid-user
      PerlSetVar BaseDir /home/httpd/html/roaming
    </Location>

By default the arrays INITIAL and ALWAYS are read via

  require Apache::Roaming::LiPrefs::Config;

This file can be generated automatically while installing the
Apache::Roaming module. However, you can overwrite this by
using the instruction

      PerlSetVar LiPrefsConfigFile /home/httpd/liprefs.cnf

In that case the variables will be read via

  require "/home/httpd/liprefs.cnf";


=head1 METHOD INTERFACE

No methods from Apache::Roaming are overwritten, there's only an
additional method, I<GET_liprefs>, that is called in favour of
I<GET> if the user requests an I<liprefs> file.


=cut

sub MakeLine {
    my($self, $var, $val) = @_;
    $val = '' unless defined($val);
    if ($val !~ /^(?:true|false|\d+(?:\.\d+))$/) {
	$val =~ s/[\\\"]/\\\"/g;
	$val = "\"$val\"";
    }
    "user_pref(\"$var\", $val);\n";
}

sub GET_liprefs {
    my $self = shift;
    my $file = $self->{'file'};
    my $r = $self->{'request'};

    my $inc = ($r->dir_config('LiPrefsConfigFile')
	       || 'Apache/Roaming/LiPrefs/Config.pm');
    require $inc unless $INC{$inc};

    my %initial = (%Apache::Roaming::LiPrefs::INITIAL,
		   %Apache::Roaming::LiPrefs::ALWAYS);

    my $contents = '';
    if (-f $file) {
	my $fh = Symbol::gensym();
	if (!open($fh, "<$file")  ||  !binmode($fh)) {
	    die "Failed to open file $file: $!";
	}

	while (defined(my $line = <$fh>)) {
	    if ($line =~ m{
                           ^\s*user_pref\s*\(
                                             \s*\"(.*?)\"\)\s*\,
                                             \s*(\S.*?)\s*
                                           \)\s*\;\s*$}) {
		my $var = $1;
		my $val = $2;
		delete $initial{$var} if exists($initial{$var});
		$line = $self->MakeLine
		    ($var, $Roaming::Apache::LiPrefs::ALWAYS{$var})
			if exists($Roaming::Apache::LiPrefs::ALWAYS{$var});
	    }
	    $contents .= $line;
	}
    }
    while (my($var, $val) = each %initial) {
	$contents .= $self->MakeLine($var, $val);
    }

    $r->content_type('text/plain');
    $r->no_cache(1);
    $r->header_out('content_length', length($contents));
    $r->set_last_modified(time());
    $r->send_http_header();
    if (!$r->header_only()) {
	$r->print($contents);
    }
    return Apache::OK();
}


1;

__END__

=pod

=head1 AUTHOR AND COPYRIGHT

This module is

    Copyright (C) 1998    Jochen Wiedmann
                          Am Eisteich 9
                          72555 Metzingen
                          Germany

                          Phone: +49 7123 14887
                          Email: joe@ispsoft.de

All rights reserved.

You may distribute this module under the terms of either
the GNU General Public License or the Artistic License, as
specified in the Perl README file.


=head1 SEE ALSO

L<Apache(3)>, L<mod_perl(3)>, L<Apache::Roaming(3)>

=cut

