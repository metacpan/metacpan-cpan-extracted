# ************************************************************************* 
# Copyright (c) 2014-2016, SUSE LLC
# 
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# 
# 1. Redistributions of source code must retain the above copyright notice,
# this list of conditions and the following disclaimer.
# 
# 2. Redistributions in binary form must reproduce the above copyright
# notice, this list of conditions and the following disclaimer in the
# documentation and/or other materials provided with the distribution.
# 
# 3. Neither the name of SUSE LLC nor the names of its contributors may be
# used to endorse or promote products derived from this software without
# specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
# ************************************************************************* 
#
# top-level CLI module
#
package App::Dochazka::CLI;

use 5.012;
use strict;
use warnings;

use App::CELL qw( $CELL );
use Data::Dumper;
use Exporter 'import';
use Test::More;



=head1 NAME

App::Dochazka::CLI - Dochazka command line client



=head1 VERSION

Version 0.240

=cut

our $VERSION = '0.240';



=head1 SYNOPSIS

Dochazka command line client.

    bash$ dochazka-cli
    Dochazka(2014-08-08) demo> 



=head1 DESCRIPTION

L<App::Dochazka::CLI> is the Command Line Interface (CLI) component of the
Dochazka Attendance & Time Tracking system. 

In order to work, the CLI must be pointed at a running L<App::Dochazka::REST>
(i.e., Dochazka REST server) instance by setting the C<< MREST_CLI_URI_BASE >>
meta configuration parameter. 

Detailed documentation covering configuration, deployment, and the commands
that can be used with the CLI can be found in L<App::Dochazka::CLI::Guide>.

This module is used to store some "global" package variables that are used
throughout the CLI code base.


=head1 PACKAGE VARIABLES AND EXPORTS

=over

=item * C<< $current_emp >>

The L<App::Dochazka::Common::Model::Employee> object of the current employee.

=item * C<< $current_priv >>

The privlevel of the current employee.

=item * C<< $debug_mode >>

Tells parser whether to display debug messages

=item * C<< $prompt_century >>

The century component of C<< $prompt_date >>; see L<App::Dochazka::CLI::Util>

=item * C<< $prompt_date >>

The date displayed in the prompt -- see C<bin/dochazka-cli> and L<App::Dochazka::CLI::Util>

=item * C<< $prompt_day >>

The day component of C<< $prompt_date >>; see L<App::Dochazka::CLI::Util>

=item * C<< $prompt_month >>

The month component of C<< $prompt_date >>; see L<App::Dochazka::CLI::Util>

=item * C<< $prompt_year >>

The year component of C<< $prompt_date >>; see L<App::Dochazka::CLI::Util>

=back

=cut

our @EXPORT_OK = qw( 
    $current_emp 
    $current_priv 
    $debug_mode
    $prompt_century
    $prompt_date 
    $prompt_day
    $prompt_month
    $prompt_year
);
our ( 
    $current_emp, 
    $current_priv, 
    $debug_mode, 
    $prompt_date, 
    $prompt_century, 
    $prompt_year, 
    $prompt_month, 
    $prompt_day, 
);

1;
