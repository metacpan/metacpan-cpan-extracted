###################################################################################
#
#   Apache::SessionX - Copyright (c) 2001 Gerald Richter / ecos gmbh
#
#   You may distribute under the terms of either the GNU General Public
#   License or the Artistic License, as specified in the Perl README file.
#
#   THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
#   IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
#   WARRANTIES OF MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#
#   $Id: Makefile.PL,v 1.3 2001/09/19 06:11:01 richter Exp $
#
###################################################################################


use ExtUtils::MakeMaker;

%Store =
    (
    'File' => 
        {
        param =>
            {
            'Store'     => 'File',
            'Lock'      => 'Semaphore',
            'Serialize' => 'Storable',
            'Directory' => '?',
            'Info'      => 'File, use semaphore for locking', 
            },
        'require'   => 
            [
            'IPC::SysV',
            ],
        },

    'FileFile' => 
        {
        param =>
            {
            'Store'     => 'File',
            'Lock'      => 'File',
            'Serialize' => 'Storable',
            'Directory' => '?',
            'LockDirectory' => '?',
            'Info'        => 'File, use lockfiles',
            },
        },

    'DB_File' => 
        {
        param =>
            {
            'Lock'      => 'File',
            'Serialize' => 'Storable',
            'FileName' => '?',
            'LockDirectory' => '?',
            },
        },

    'Mysql' => 
        {
        param =>
            {
            'Store'     => 'MySQL',
            'Lock'      => 'Semaphore',
            'Serialize' => 'Storable',
            'DataSource' => '?',
            'UserName'   => '?',
            'Password'   => '?',
            'Info'       => 'MySQL, use semaphore for locking',
            },
        'require'   => 
            [
            'DBD::mysql',
            'IPC::SysV',
            ],
        },

    'MysqlMysql' => 
        {
        param =>
            {
            'Store'     => 'MySQL',
            'Lock'      => 'MySQL',
            'Serialize' => 'Storable',
            'DataSource' => '?',
            'UserName'   => '?',
            'Password'   => '?',
            'LockDataSource' => '?',
            'LockUserName'   => '?',
            'LockPassword'   => '?',
            'Info'           => 'MySQL, use MySQL for locking',
            },
        'require'   => 
            [
            'DBD::mysql',
            ],
        },

    'Oracle' => 
        {
        param =>
            {
            'Lock'      => 'Null',
            'Serialize' => 'Base64',
            'Commit'     => 1,
            'DataSource' => '?',
            'UserName'   => '?',
            'Password'   => '?',
            },
        'require'   => 
            [
            'DBD::Oracle',
            ],
        },
    'Sybase' =>
        {
        param =>
            {
            'Lock'      => 'Null',
            'Serialize' => 'Sybase',
            'Commit'     => 1,
            'DataSource' => '?',
            'UserName'   => '?',
            'Password'   => '?',
            },
        'require'   => 
            [
            'DBD::Sybase',
            ],
        },
    'Postgres' => 
        {
        param =>
            {
            'Lock'      => 'Null',
            'Serialize' => 'Base64',
            'Commit'     => 1,
            'DataSource' => '?',
            'UserName'   => '?',
            'Password'   => '?',
            },
        'require'   => 
            [
            'DBD::Pg',
            ],
        },
    ) ;

## ----------------------------------------------------------------------------

sub GetString
	{
	my ($prompt, $default) = @_ ;

	printf ("%s [%s]", $prompt, $default) ;
	chop ($_ = <STDIN>) ;
        #$_ = prompt ($prompt, $default) ;
	if (!/^\s*$/)
	    {return $_ ;}
	else
    	{
        if ($_ eq "")
	        {return $default ;}
	    else
            { return "" ; }
    
        }
    }

## ----------------------------------------------------------------------------

sub GetYesNo
	{
	my ($prompt, $default) = @_ ;
	my ($value) ;

	do
	    {
	    $value = lc (GetString ($prompt . "(y/n)", ($default?"y":"n"))) ;
	    }
	until (($value cmp "j") == 0 || ($value cmp "y") == 0 || ($value cmp "n" ) == 0) ;

	return ($value cmp "n") != 0 ;
	}


# --------------------------------------------------------------------------- 

print "\nChecking configuration...\n" ;

store:
foreach $store (sort keys %Store)
    {
    $data = $Store{$store} ;
    $info = $data -> {param}{Info} ||= $store ;
    if ($data -> {'require'})
        {
        foreach $require (@{$data -> {'require'}})
            {
            eval "require $require" ;
            if ($@)
                {
                print "Storage '$info' is unavailable because $require is not installed on your system\n" ;
                next store ;
                }
            }
        }
    push @avail, $store ;
    }

print "\nThe following ways to store session are available on your system:\n" ;

foreach $store (@avail)
    {
    $data = $Store{$store} ;
    $info = $data -> {param}{Info} ;

    printf (" - %-20s: %s\n", $store, $info) ;
    }


eval { require 'SessionX/Config.pm' ; } ;
if (!keys %Apache::SessionX::Config::param)
    {
    eval { require Apache::SessionX::Config ; } ;
    }

if (keys %Apache::SessionX::Config::param)
    {
    %param = %Apache::SessionX::Config::param ;
    @conf  = @Apache::SessionX::Config::confs ;
    $input = GetYesNo ("Found previous configuration. Modify it", 0) ;
    }
else
    {
    %param = map { $_ => {} } @avail ;
    $input = 1 ;
    }

if ($input)
    {
    @conf = () ;
    print "\n" ;
    print "You can now specify the configuration parameters for every storage.\n" ;
    print "Apache::SessionX uses this for testing your system and stores it for later\n" ;
    print "use in your application. You can override these default parameters anytime\n" ;
    print "at runtime. You can change them by rerunning Makefile.PL.\n" ;
    print "\nIf you don't plan to use different storages for session, \nonly say Yes to the one storage you want to use.\n" ;

    foreach $store (@avail)
        {
        print "\n" ;
        $data = $Store{$store} ;
        $info = $data -> {param}{Info} ;
        if (GetYesNo("Would you like to configure $info ($store)", $param{$store}?1:0))
            {
            push @conf, $store ;
            $param{$store} = { %{$data->{param}} } if (!keys %{$param{$store}}) ;
            while (($param, $value) = each (%{$data->{param}}))
                {
                if ($value eq '?')
                    {
                    $value = GetString ($param, $param{$store}{$param} eq '?'?'':$param{$store}{$param}) ;
                    $param{$store}{$param} = $value ;
                    }
                }
            $param{$store}{'Store'}     ||= $store ;
            $param{$store}{'Serialize'} ||= 'Storeable' ;
            $param{$store}{'Lock'}      ||= 'Semaphore' ;
            $param{$store}{'Generate'}  ||= 'MD5' ;
            }
        }

    print "\n" ;
    $i = 1 ;
    foreach $store (@conf)
        {
        $data = $Store{$store} ;
        $info = $data -> {param}{Info} ;
        print " $i: $info ($store)\n" ;
        $def = $i if ($Apache::SessionX::Config::default eq $store) ;
        $i++ ;
        }

    $i--  ;
    if ($i == 1)
        {
        $default = 0 ;
        }
    else
        {
        $default = GetString ("Which of the above should be your default store (1-$i)", $def || '') ;
        $default-- ;
        }
    }

print "Using $conf[$default] as default\n" ;

open FH, ">SessionX/Config.pm" or die "Cannot open SessionX/Config.pm for writing ($!)" ;
print FH qq{
#
# Apache::SessionX configuration
#
# Autogenerated by Makefile.PL, do not edit!
#

package Apache::SessionX::Config ;

\$default = '$conf[$default]' ;

\@confs   = ('} ;

print FH join ("','", @conf) ;

print FH qq{') ; 
\%param   =
    (
} ;

foreach $store (@conf)
    {
    $p = $param{$store} ;
    print FH "    '$store' => \n" ;
    print FH "        {\n" ;
    while (($param, $value) = each (%$p))
        {
        print FH "         '$param' => '$value',\n" ;
        }
    print FH "        },\n" ;
    }

print FH qq{
    ) ;

\$defaultparam = \$param{'$conf[$default]'} ;

1 ;

} ;

close FH ;

# --------------------------------------------------------------------------- 

WriteMakefile
    (
    'NAME'	=> 'Apache::SessionX',
    'VERSION_FROM' => 'SessionX.pm', # finds $VERSION
    'PREREQ_PM'    => { 'Apache::Session' => 1.53 },
    'ABSTRACT'     => 'Web Session Management - based on Apache::Session',
    'AUTHOR'       => 'Gerald Richter <richter@dev.ecos.de>',
    );
