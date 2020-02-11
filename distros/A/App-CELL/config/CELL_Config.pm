# ************************************************************************* 
# Copyright (c) 2014-2020, SUSE LLC
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

#-------------------------------------------------------------#
# CELL_Config.pm
#
# App::CELL's own core configuration parameters. This file
# is stored in the "distro sharedir" and is always loaded 
# before the files in the application sitedir.
#
# In addition to being used by App::CELL, the files in the
# distro sharedir (CELL_MetaConfig.pm, CELL_Config.pm, and
# CELL_SiteConfig.pm along with CELL_Message_en.conf,
# CELL_Message_cz.conf, etc.) can be used as models for 
# populating the application sitedir.
#
# See App::CELL::Guide for details.
#-------------------------------------------------------------#

# CELL_DEBUG_MODE
#        debug mode means that calls to $log->trace and $log->debug
#        won't be suppressed - off by default
set( 'CELL_DEBUG_MODE', 0 );

# boolean value expressing whether sharedir has been loaded
# (defaults to 1 since the param is initialized only when distro sharedir
# is loaded)
set( 'CELL_SHAREDIR_LOADED', 1 );

# CELL_SHAREDIR_FULLPATH
#        full path of App::CELL distro sharedir
#        overrided by site param when sharedir is loaded
set( 'CELL_SHAREDIR_FULLPATH', '' );

# CELL_SUPP_LANG
#        reference to a list of supported language tags
#        (i.e. languages for which we have _all_ messages
#        translated)
set( 'CELL_SUPP_LANG', [ 'en' ] );

# CELL_DEF_LANG
#        the language that messages will be displayed in by default,
#        when no language is specified by other means
set( 'CELL_DEF_LANG', 'en' );

# CELL_CORE_UNIT_TESTING
#        used only for App::CELL unit tests
set( 'CELL_CORE_UNIT_TESTING', [ 'nothing special' ] );

# CELL_LOAD_SANITY_CORE
#        used by App::CELL::Load::init sanity check
set( 'CELL_LOAD_SANITY_CORE', 'Bar' );

# CELL_CORE_SAMPLE
#        sample core variable (for demo purposes)
set( 'CELL_CORE_SAMPLE', 'layers of sediments' );

# CELL_LOG_SHOW_CALLER
#        determine whether App::CELL::Log appends file and line number of
#        caller to log messages
set( 'CELL_LOG_SHOW_CALLER', 1 );

#-------------------------------------------------------------#
#           DO NOT EDIT ANYTHING BELOW THIS LINE              #
#-------------------------------------------------------------#
use strict;
use warnings;
1;
