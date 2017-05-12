#!/usr/bin/env perl
# ----------------------------------------------------------------------------------------------------------
# © Copyright 2003-2011 by Alex Peeters [alex.peeters@citap.be]
# ----------------------------------------------------------------------------------------------------------
# 2011/mm/dd, v3.002.003, check_template-WebTransact.pl
# ----------------------------------------------------------------------------------------------------------

use strict;
use warnings;           # Must be used in test mode only. This reduces a little process speed
#use diagnostics;       # Must be used in test mode only. This reduces a lot of process speed

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

BEGIN { if ( $ENV{ASNMTAP_PERL5LIB} ) { eval 'use lib ( "$ENV{ASNMTAP_PERL5LIB}" )'; } }

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use ASNMTAP::Asnmtap::Plugins v3.002.003;
use ASNMTAP::Asnmtap::Plugins qw(:PLUGINS);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $objectPlugins = ASNMTAP::Asnmtap::Plugins->new (
  _programName        => 'check_template-WebTransact.pl',
  _programDescription => "WebTransact plugin template for testing the '$APPLICATION'",
  _programVersion     => '3.002.003',
  _programGetOptions  => ['environment|e:s', 'proxy:s', 'timeout|t:i', 'trendline|T:i'],
  _timeout            => 30,
  _debug              => 0);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use ASNMTAP::Asnmtap::Plugins::WebTransact;

my @URLS = ();
my $objectWebTransact = ASNMTAP::Asnmtap::Plugins::WebTransact->new ( \$objectPlugins, \@URLS );

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Start plugin  - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

$objectPlugins->pluginValue ( message => 'www.citap.be/www.citap.com' );

@URLS = (
  { Method => 'GET',  Url => 'http://www.citap.be/', Qs_var => [], Qs_fixed => [], Exp => "", Exp_Fault => ">>>NIHIL<<<", Msg => "Consulting Internet Technology Alex Peeters", Msg_Fault => "Consulting Internet Technology Alex Peeters", Perfdata_Label => 'Label 1' },
  { Method => 'GET',  Url => 'http://www.citap.be/', Qs_var => [], Qs_fixed => [], Exp => "Consulting Internet Technology Alex Peeters", Exp_Fault => ">>>NIHIL<<<", Msg => "Consulting Internet Technology Alex Peeters", Msg_Fault => "Consulting Internet Technology Alex Peeters", Perfdata_Label => 'Label 1' },
);

my $returnCode = $objectWebTransact->check ( { } );

unless ( $returnCode ) {
  use constant EXP_TITLE_1 => "\Q<TITLE>\E(Consulting Internet Technology Alex Peeters)\Q</TITLE>\E";
  use constant EXP_TITLE_2 => "\Q<TITLE>\E(Consulting) (Internet) (Technology) (Alex Peeters)\Q</TITLE>\E";

  use constant EXP_SUBMAIN => "\Q<FRAME NAME=\"NO_INFO\" SRC=\"\E(submain.htm)\Q\" SCROLLING=\"No\" FRAMEBORDER=\"0\" NORESIZE>\E";
  use constant VAL_SUBMAIN => [0, sub { my %pages = ( 'index.htm' => 'InDeX', 'submain.htm' => 'subMAIN' ); $pages { $_[0] }; } ];
  use constant RET_SUBMAIN => [0, sub { my %returns = %{ $objectWebTransact->returns() }; defined $returns { 'submain' } ? $returns { 'submain' } : ''; } ];
  use constant RET_TITLE1  => [0, sub { my %returns = %{ $objectWebTransact->returns() }; defined $returns { 'title1' } ? $returns { 'title1' } : ''; } ];

  @URLS = (
    { Method => 'GET',  Url => 'http://www.citap.com/', Qs_var => [], Qs_fixed => [], Exp => [EXP_SUBMAIN, 'Consulting Internet Technology Alex Peeters'], Exp_Fault => ">>>NIHIL<<<", Msg => "Consulting Internet Technology Alex Peeters", Msg_Fault => "Consulting Internet Technology Alex Peeters", Perfdata_Label => 'Label 2' },
    { Method => 'GET',  Url => 'http://www.citap.com/', Qs_var => [parameter => 0], Qs_fixed => [], Exp => [EXP_SUBMAIN, 'Consulting Internet Technology Alex Peeters'], Exp_Fault => ">>>NIHIL<<<", Exp_Return => { title1 => EXP_TITLE_1 }, Msg => "Consulting Internet Technology Alex Peeters", Msg_Fault => "Consulting Internet Technology Alex Peeters", Perfdata_Label => 'Label 2' },
    { Method => 'GET',  Url => 'http://www.citap.com/', Qs_var => [parameter => VAL_SUBMAIN, submain => RET_SUBMAIN, title1 => RET_TITLE1], Qs_fixed => [], Exp => 'Consulting Internet Technology Alex Peeters', Exp_Fault => ">>>NIHIL<<<", Exp_Return => { title2 => EXP_TITLE_2, submain => EXP_SUBMAIN }, Msg => "Consulting Internet Technology Alex Peeters", Msg_Fault => "Consulting Internet Technology Alex Peeters", Perfdata_Label => 'Label 3' },
  );

  $returnCode = $objectWebTransact->check ( { }, custom => \&customWebTransact );
  my %returns = %{ $objectWebTransact->returns() };
  $objectPlugins->pluginValues ( { alert => $returns {title1} .' - '. $returns {submain} .' - '. $returns {title2}[0] .' - '. $returns {title2}[1] .' - '. $returns {title2}[2] .' - '. $returns {title2}[3] }, $TYPE{REPLACE} );
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# End plugin  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

undef $objectWebTransact;
$objectPlugins->exit (7);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub customWebTransact {
  for ( $_[0] ) {
    /Failure of server APACHE bridge/ &&
      do { return ( $ERRORS{CRITICAL}, 1, 'Failure of server APACHE bridge' ); last; };
    /Message from the NSAPI plugin:/ && /No backend server available for connection:/ &&
      do { return ( $ERRORS{CRITICAL}, 1, "'KBOWI - Message from the NSAPI plugin - No backend server available for connection'" ); last; };
    /\Q<FRAME NAME="NO_INFO" SRC="submain.html" SCROLLING="No" FRAMEBORDER="0" NORESIZE>\E/ &&
      do { return ( $ERRORS{CRITICAL}, 0, '+submain+' ); last; };
    return ( $ERRORS{OK}, 0, undef );
  }
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

__END__

=head1 NAME

check_template-WebTransact.pl

WebTransact plugin template for testing the 'Application Monitor'

The ASNMTAP plugins come with ABSOLUTELY NO WARRANTY.

=head1 AUTHOR

Alex Peeters [alex.peeters@citap.be]

=head1 COPYRIGHT NOTICE

(c) Copyright 2000-2011 by Alex Peeters [alex.peeters@citap.be],
                        All Rights Reserved.

=head1 LICENSE

This ASNMTAP CPAN library and Plugin templates are free software; you can redistribute it and/or modify it under the same terms as Perl itself.

The other parts of ASNMTAP may be used and modified free of charge by anyone so long as this copyright notice and the comments above remain intact. By using this code you agree to indemnify Alex Peeters from any liability that might arise from it's use.

Selling the code for this program without prior written consent is expressly forbidden. In other words, please ask first before you try and make money off of my program.

Obtain permission before redistributing this software over the Internet or in any other medium. In all cases copyright and header must remain intact.

=cut
