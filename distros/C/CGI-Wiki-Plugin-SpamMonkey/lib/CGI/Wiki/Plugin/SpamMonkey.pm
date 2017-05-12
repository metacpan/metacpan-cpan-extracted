package CGI::Wiki::Plugin::SpamMonkey;
use strict;

our $VERSION = '0.03';

use base 'CGI::Wiki::Plugin';
use SpamMonkey;
use Data::Dumper;

sub new {
    my ($class) = @_;
    my $newhome;
    if (!exists $ENV{HOME}) {
        $newhome = $ENV{HOMEDRIVE} . $ENV{HOMEPATH}
            if exists $ENV{HOMEDRIVE}; # Win XP/2000
    }
    local $ENV{HOME} = $newhome if $newhome;
    my $monkey = SpamMonkey->new( rule_dir => "/etc/mail/spamassassin/");
    $monkey->ready;
    my $self = bless ({ monkey => $monkey}, $class);

    return $self;
}

sub is_spam {
    my ($self,%args) = @_;

    my $content = $args{content} || '';
    $content .= Dumper($args{metadata}) if exists $args{metadata};

    my $result = $self->{monkey}->test($content);
    return $result->is_spam;
}

=head1 NAME

CGI::Wiki::Plugin::SpamMonkey - CGI::Wiki plugin for SpamMonkey

=head1 SYNOPSIS

  use CGI::Wiki::Plugin::SpamMonkey;
  my $plugin = CGI::Wiki::Plugin::SpamMonkey->new;
  $wiki->register_plugin( plugin => $plugin );
  ...
  if ($plugin->is_spam( content => $content, metadata => \%metadata)) {
      $wiki->redirect( '/spamerror.html' );
  }
  else {
      $wiki->commit(...);
  }

=head1 DESCRIPTION

This module is a plugin for CGI::Wiki sites to interface with the SpamMonkey
module.

=head1 USAGE

  $plugin->is_spam( content => $content, metadata => \%metadata)

Returns a true value if the content or metadata is spam.

=head1 BUGS

Please report any bugs to rt.cpan.org or post to 
bugs-cgi-wiki-plugin-spammonkey at rt.cpan.org

=head1 SUPPORT

This module, and other related modules are discussed on the mailing list:
http://www.earth.li/cgi-bin/mailman/listinfo/cgi-wiki-dev

=head1 AUTHOR

	Ivor Williams
	CPAN ID: IVORW
	 
	ivorw-openguides at xemaps.com
	http://openguides.org/

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

perl(1).

=cut

1;

