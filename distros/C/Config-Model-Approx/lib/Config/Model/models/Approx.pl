#
# This file is part of Config-Model-Approx
#
# This software is Copyright (c) 2013 by Dominique Dumont.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
[
  {
    'class_description' => 'Configuration model for Approx',
    'accept' => [
      '.*',
      {
        'value_type' => 'uniline',
        'summary' => 'unknown parameter',
        'type' => 'leaf',
        'description' => 'Either the configuration file has an error or the author of this
module forgot to implement this parameter. In the latter case, please
file a bug on CPAN request tracker:
http://rt.cpan.org/NoAuth/Bugs.html?Dist=Config-Model-Approx'
      }
    ],
    'name' => 'Approx',
    'copyright' => [
      '2011, Dominique Dumont'
    ],
    'author' => [
      'Dominique Dumont'
    ],
    'license' => 'LGPL-2.1+',
    'element' => [
      'cache',
      {
        'value_type' => 'uniline',
        'summary' => 'approx cache directory',
        'upstream_default' => '/var/cache/approx',
        'experience' => 'advanced',
        'type' => 'leaf',
        'description' => 'Specifies the location of the approx cache directory (default: /var/cache/approx). It and all its subdirectories must be owned by the approx server (see also the $user and $group parameters, below.)'
      },
      'interval',
      {
        'value_type' => 'integer',
        'summary' => 'file cache expiration in minutes',
        'upstream_default' => '720',
        'experience' => 'advanced',
        'type' => 'leaf',
        'description' => 'Specifies the time in minutes after which a cached file will be considered too old to deliver without first checking with the remote repository for a newer version'
      },
      'max_rate',
      {
        'value_type' => 'uniline',
        'summary' => 'maximum download rate from remote repositories',
        'type' => 'leaf',
        'description' => 'Specifies the maximum download rate from remote repositories, in bytes per second (default: unlimited). The value may be suffixed with "K", "M", or "G" to indicate kilobytes, megabytes, or gigabytes per second, respectively.'
      },
      'max_redirects',
      {
        'value_type' => 'integer',
        'summary' => 'maximum number of HTTP redirections',
        'upstream_default' => '5',
        'type' => 'leaf',
        'description' => 'Specifies the maximum number of HTTP redirections that will be followed when downloading a remote file'
      },
      'user',
      {
        'value_type' => 'uniline',
        'summary' => 'user that owns the files in the approx cache',
        'upstream_default' => 'approx',
        'type' => 'leaf'
      },
      'group',
      {
        'value_type' => 'uniline',
        'summary' => 'group that owns the files in the approx cache',
        'upstream_default' => 'approx',
        'type' => 'leaf'
      },
      'syslog',
      {
        'value_type' => 'uniline',
        'summary' => 'syslog(3) facility to use when logging',
        'upstream_default' => 'daemon',
        'type' => 'leaf'
      },
      'pdiffs',
      {
        'value_type' => 'boolean',
        'summary' => 'support IndexFile diffs',
        'upstream_default' => '1',
        'type' => 'leaf'
      },
      'offline',
      {
        'value_type' => 'boolean',
        'summary' => 'use cached files when offline',
        'upstream_default' => '0',
        'type' => 'leaf',
        'description' => 'Specifies whether to deliver (possibly out-of-date) cached files when they cannot be downloaded from remote repositories'
      },
      'max_wait',
      {
        'value_type' => 'integer',
        'summary' => 'max wait for concurrent file download',
        'upstream_default' => '10',
        'type' => 'leaf',
        'description' => 'Specifies how many seconds an approx(8) process will wait for a concurrent download of a file to complete, before attempting to download the file itself'
      },
      'verbose',
      {
        'value_type' => 'boolean',
        'upstream_default' => '0',
        'type' => 'leaf',
        'description' => 'Specifies whether informational messages should be printed in the log'
      },
      'debug',
      {
        'value_type' => 'boolean',
        'upstream_default' => '0',
        'type' => 'leaf',
        'description' => 'Specifies whether debug messages should be printed in the log'
      },
      'distributions',
      {
        'level' => 'important',
        'cargo' => {
          'value_type' => 'uniline',
          'type' => 'leaf'
        },
        'summary' => 'remote repositories',
        'type' => 'hash',
        'description' => 'The other name/value pairs are used to map distribution names to remote repositories. For example,

  debian     =>   http://ftp.debian.org/debian
  security   =>   http://security.debian.org/debian-security

Use the distribution name as the key of the hash element and the URL as the value
',
        'index_type' => 'string'
      }
    ],
    'read_config' => [
      {
        'file' => 'approx.conf',
        'backend' => 'Approx',
        'config_dir' => '/etc/approx'
      }
    ]
  }
]
;

