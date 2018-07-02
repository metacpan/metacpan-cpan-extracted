#
# This file is part of Config-Model-Approx
#
# This software is Copyright (c) 2015-2018 by Dominique Dumont.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
[
  {
    'accept' => [
      '.*',
      {
        'description' => 'Either the configuration file has an error or the author of this
module forgot to implement this parameter. In the latter case, please
file a bug on CPAN request tracker:
http://rt.cpan.org/NoAuth/Bugs.html?Dist=Config-Model-Approx',
        'summary' => 'unknown parameter',
        'type' => 'leaf',
        'value_type' => 'uniline'
      }
    ],
    'author' => [
      'Dominique Dumont'
    ],
    'class_description' => 'Configuration model for Approx',
    'copyright' => [
      '2011, Dominique Dumont'
    ],
    'element' => [
      'cache',
      {
        'description' => 'Specifies the location of the approx cache directory (default: /var/cache/approx). It and all its subdirectories must be owned by the approx server (see also the $user and $group parameters, below.)',
        'summary' => 'approx cache directory',
        'type' => 'leaf',
        'upstream_default' => '/var/cache/approx',
        'value_type' => 'uniline'
      },
      'interval',
      {
        'description' => 'Specifies the time in minutes after which a cached file will be considered too old to deliver without first checking with the remote repository for a newer version',
        'summary' => 'file cache expiration in minutes',
        'type' => 'leaf',
        'upstream_default' => '720',
        'value_type' => 'integer'
      },
      'max_rate',
      {
        'description' => 'Specifies the maximum download rate from remote repositories, in bytes per second (default: unlimited). The value may be suffixed with "K", "M", or "G" to indicate kilobytes, megabytes, or gigabytes per second, respectively.',
        'summary' => 'maximum download rate from remote repositories',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'max_redirects',
      {
        'description' => 'Specifies the maximum number of HTTP redirections that will be followed when downloading a remote file',
        'summary' => 'maximum number of HTTP redirections',
        'type' => 'leaf',
        'upstream_default' => '5',
        'value_type' => 'integer'
      },
      'user',
      {
        'summary' => 'user that owns the files in the approx cache',
        'type' => 'leaf',
        'upstream_default' => 'approx',
        'value_type' => 'uniline'
      },
      'group',
      {
        'summary' => 'group that owns the files in the approx cache',
        'type' => 'leaf',
        'upstream_default' => 'approx',
        'value_type' => 'uniline'
      },
      'syslog',
      {
        'summary' => 'syslog(3) facility to use when logging',
        'type' => 'leaf',
        'upstream_default' => 'daemon',
        'value_type' => 'uniline'
      },
      'pdiffs',
      {
        'summary' => 'support IndexFile diffs',
        'type' => 'leaf',
        'upstream_default' => '1',
        'value_type' => 'boolean'
      },
      'offline',
      {
        'description' => 'Specifies whether to deliver (possibly out-of-date) cached files when they cannot be downloaded from remote repositories',
        'summary' => 'use cached files when offline',
        'type' => 'leaf',
        'upstream_default' => '0',
        'value_type' => 'boolean'
      },
      'max_wait',
      {
        'description' => 'Specifies how many seconds an approx(8) process will wait for a concurrent download of a file to complete, before attempting to download the file itself',
        'summary' => 'max wait for concurrent file download',
        'type' => 'leaf',
        'upstream_default' => '10',
        'value_type' => 'integer'
      },
      'verbose',
      {
        'description' => 'Specifies whether informational messages should be printed in the log',
        'type' => 'leaf',
        'upstream_default' => '0',
        'value_type' => 'boolean'
      },
      'debug',
      {
        'description' => 'Specifies whether debug messages should be printed in the log',
        'type' => 'leaf',
        'upstream_default' => '0',
        'value_type' => 'boolean'
      },
      'distributions',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'description' => 'The other name/value pairs are used to map distribution names to remote repositories. For example,

  debian     =>   http://ftp.debian.org/debian
  security   =>   http://security.debian.org/debian-security

Use the distribution name as the key of the hash element and the URL as the value
',
        'index_type' => 'string',
        'level' => 'important',
        'summary' => 'remote repositories',
        'type' => 'hash'
      }
    ],
    'license' => 'LGPL-2.1+',
    'name' => 'Approx',
    'rw_config' => {
      'backend' => 'Approx',
      'config_dir' => '/etc/approx',
      'file' => 'approx.conf'
    }
  }
]
;

