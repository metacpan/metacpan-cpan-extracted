# *************************************************************************
# Copyright (c) 2014-2017, SUSE LLC
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

# Component_Config.pm - component-related configuration defaults


# DOCHAZKA_COMPONENT_DEFINITIONS
#    Initial set of component definitions - sample only - can be overridden
set( 'DOCHAZKA_COMPONENT_DEFINITIONS', [
  {
    path => 'sample/local_time.mc',
    source => 'Hello! The local time is <% scalar(localtime) %>.',
    acl => 'passerby',
  },
  {
    path => 'sample/site_param.mc',
    source => <<'EOS',
<%class>
has 'param' => (isa => 'Str', required => 1);
use Data::Dumper;
</%class>
<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01//EN"
    "http://www.w3.org/TR/html4/strict.dtd">
<html lang="en">
  <head>
    <meta http-equiv="content-type" content="text/html; charset=utf-8">
    <title>Dochazka Site Param</title>
  </head>
  <body>
<pre>
$site_param_name = '<% $.param %>';
<% Data::Dumper->Dump( [ $site->get($.param) ], [ 'site_param_value' ] ) %>
</pre>
  </body>
</html>
EOS
    acl => 'admin',
    validations => q/{ 'param' => { 'type' => SCALAR } }/,
  },
  {
    path => 'suse-cz-monthly.mc',
    source => <<'EOS',
<%class>
has 'employee' => (isa => 'HashRef', required => 1);
has 'tsrange' => (isa => 'Str', required => 1);
use Data::Dumper;
</%class>
<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01//EN"
    "http://www.w3.org/TR/html4/strict.dtd">
<html lang="en">
  <head>
    <meta http-equiv="content-type" content="text/html; charset=utf-8">
    <title>Dochazka Monthly Report</title>
  </head>
  <body>
<pre>
<% Data::Dumper->Dump( [ $.employee ], [ 'employee' ] ) %>
$tsrange = '<% $.tsrange %>';
</pre>
  </body>
</html>
EOS
    acl => 'active',
    validations => q/
{
    employee => { type => HASHREF },
    tsrange => { type => SCALAR },
}
    /,
  },
#  {
#    path => '',
#    source => '',
#    acl => 'passerby',
#  },
] );


# -----------------------------------
# DO NOT EDIT ANYTHING BELOW THIS LINE
# -----------------------------------
use strict;
use warnings;

1;
