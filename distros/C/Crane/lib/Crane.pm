# -*- coding: utf-8 -*-


package Crane;


use Crane::Base;
use Crane::Config;
use Crane::Options qw( :opts options );

use File::Basename qw( basename dirname );
use File::Find qw( find );
use File::Spec::Functions qw( catdir splitdir );


our $VERSION = '1.03.0011';


sub get_package_path {
    
    my ( $package ) = @_;
    
    my @path      = split m{::}si, $package;
       $path[-1] .= '.pm';
    
    return catdir(@path);
    
}


sub create_package_alias {
    
    my ( $original, $alias ) = @_;
    
    eval qq{
        package $alias;
        
        use $original;
        
        1;
    } or do {
        confess($EVAL_ERROR);
    };
    
    # Tell to Perl that module is read
    $INC{ get_package_path($alias) } = $INC{ get_package_path($original) };
    
    {
        no strict 'refs';
        
        # Create alias
        *{ "${alias}::" } = \*{ "${original}::" };
    }
    
    return;
    
}


sub import {
    
    my ( undef, %params ) = @_;
    
    my $caller = caller;
    
    Crane::Base->import(ref $params{'base'} eq 'ARRAY' ? @{ $params{'base'} } : ());
    Crane::Base->export_to_level(1, $caller);
    
    {
        no strict 'refs';
        push @{ "${caller}::ISA" }, @{ __PACKAGE__ . '::ISA' };
    }
    
    # Predefined options
    my @options = (
        [ 'daemon|M!',     'Run as daemon.', { 'default' => $params{'name'} ? 1 : 0 } ],
        $OPT_SEPARATOR,
        [ 'config|C=s',    'Path to configuration file.' ],
        [ 'pid|P=s',       'Path to PID file.' ],
        $OPT_SEPARATOR,
        [ 'log|O=s',       'Path to log file.' ],
        [ 'log-error|E=s', 'Path to error log file.' ],
        $OPT_SEPARATOR,
        [ 'debug|D!',      'Debug output.' ],
        [ 'verbose|V!',    'Verbose output.' ],
        $OPT_SEPARATOR,
        $OPT_VERSION,
        $OPT_HELP,
    );
    
    # Custom options are going to the head
    if ( ref $params{'options'} eq 'ARRAY' ) {
        unshift @options, @{ $params{'options'} }, $OPT_SEPARATOR;
    }
    
    options(@options);
    
    # User defined settings
    if ( ref $params{'config'} eq 'HASH' ) {
        config(
            $params{'config'},
            options->{'config'} ? options->{'config'} : (),
        );
    }
    
    # Create namespace
    if ( defined $params{'namespace'} ) {
        no warnings 'File::Find';
        
        my $path = catdir(dirname(__FILE__), __PACKAGE__);
        
        # Create alias for root package
        create_package_alias(__PACKAGE__, $params{'namespace'});
        
        # Create alias for each subpackage
        my @packages = ();
        
        find(
            sub {
                if ( my ( $filename ) = $File::Find::name =~ m{^\Q$path\E/?(.+)[.]pm$}si ) {
                    push @packages, join '::', splitdir($filename);
                }
            },
            
            $path,
        );
        
        foreach my $package ( @packages ) {
            create_package_alias(__PACKAGE__ . "::$package", $params{'namespace'} . "::$package");
        }
    }
    
    # Run as daemon
    if ( options->{'daemon'} ) {
        local $OUTPUT_AUTOFLUSH = 1;
        
        $params{'name'} //= basename($PROGRAM_NAME) =~ s{[.]p[lm]$}{}rsi;
        
        # Prepare PID file
        my $pid_filename = options->{'pid'} || catdir('run', "$params{'name'}.pid");
        my $pid_prev     = undef;
        
        open my $fh_pid, '+>>:encoding(UTF-8)', $pid_filename or confess($OS_ERROR);
        seek $fh_pid, 0, 0;
        
        $pid_prev = <$fh_pid>;
        
        if ( $pid_prev ) {
            chomp $pid_prev;
        }
        
        # Check if process is already running
        my $is_working = $pid_prev ? kill 0, $pid_prev : 0;
        
        if ( not $is_working ) {
            # Fork
            if ( my $pid = fork ) {
                truncate $fh_pid, 0;
                print { $fh_pid } "$pid\n" or confess($OS_ERROR);
                close $fh_pid              or confess($OS_ERROR);
                
                exit 0;
            }
        } else {
            die "Process is already running: $pid_prev\n";
        }
        
        close $fh_pid or confess($OS_ERROR);
    }
    
    return;
    
}


1;


=head1 NAME

Crane - Helpers for development in Perl


=head1 SYNOPSIS

  use Crane;
  
  ...
  
  use Crane ( 'name' => 'example' );


=head1 DESCRIPTION

Helpers for development in Perl. Includes the most modern technics and rules.

Also imports modules as L<Crane::Base/Crane::Base>;


=head2 Import options

You can specify these options when using module:

=over

=item B<name>

Script name, used when run as daemon.

If defined, run as daemon by default. Use B<--no-daemon> command line option to
cancel this behavior.

=item B<base>

Array (reference) to list of base modules.

=item B<options>

Array (reference) of options which will be added to the head of L<default options|/"OPTIONS"> list.

=item B<config>

Hash (reference) with user defined default settings.

=item B<namespace>

Custom namespace. Please, look at L<examples|/"EXAMPLES"> below.

=back


=head1 OPTIONS

These options are available by default. You can define your custom options if
specify it in the import options.

=over

=item B<-M>, B<--daemon>, B<--no-daemon>

Runs as daemon.

=item B<-C> I<path/to/config>, B<--config>=I<path/to/config>

Path to configuration file.

=item B<-P> I<path/to/file_with.pid>, B<--pid>=I<path/to/file_with.pid>

Path to PID file.

=item B<-O> I<path/to/messages.log>, B<--log>=I<path/to/messages.log>

Path to messages log file.

=item B<-E> I<path/to/errors.log>, B<--log-error>=I<path/to/errors.log>

Path to errors log file.

=item B<-D>, B<--debug>, B<--no-debug>

Debug output.

=item B<-V>, B<--verbose>, B<--no-verbose>

Verbose output.

=item B<--version>

Shows version information and exits.

=item B<--help>

Shows help and exits.

=back


=head1 RETURN VALUE

In case of running as daemon will return 1 if process is already running.


=head1 DIAGNOSTICS

=over

=item Process is already running: I<%d>

Where I<%d> is a PID.

You tried to run application as daemon while another copy is running.

=back


=head1 EXAMPLES


=head2 Singleton usage

  use Crane;
  
  ...
  
  use Crane ( 'base' => qw( Mojolicious::Controller ) );


=head2 Daemon usage

  use Crane ( 'name' => 'example' );


=head2 Configure options

  use Crane ( 'options' => [
      [ 'from|F=s', 'Start of the interval.', { 'required' => 1 } ],
      [ 'to|F=s',   'End of the interval.',   { 'required' => 1 } ],
  ] );

As a result you have these two options, a separator and default options.


=head2 Basic namespace usage

  package My;
  
  use Crane (
      'namespace' => 'My',
      
      'config' => {
          'my' => {
              'autorun' => 1,
              
              'hosts' => [
                  '127.0.0.1',
                  '127.0.0.2',
              ],
          },
      },
  );
  
  1;
  
  ...
  
  use My;
  use My::Config;
  use My::Logger;
  
  log_info(config->{'log'});


=head2 Advanced namespace usage

  package My;
  
  use Crane::Base;
  use Crane::Options qw( :opts );
  
  require Crane;
  
  sub import {
      my ( $package, $name ) = @_;
      
      Crane->import(
          'namespace' => 'My',
          'name'      => $name,
          
          'options' => [
              [ 'run!',    'Do action at startup.' ],
              $OPT_SEPARATOR,
              [ 'host=s@', 'Host name(s).' ],
          ],
          
          'config' => {
              'my' => {
                  'autorun' => 1,
                  
                  'hosts' => [
                      '127.0.0.1',
                      '127.0.0.2',
                  ],
              },
          },
      );
      
      return;
  }
  
  1;
  
  ...
  
  use My 'my_script';
  
  sub main {
      ...
      
      return 0;
  }
  
  exit main();


=head1 ENVIRONMENT

See L<Crane::Base|Crane::Base/"ENVIRONMENT">.


=head1 FILES

=over

=item F<etc/*.conf>

Configuration files. See L<Crane::Config|Crane::Config/"FILES">.

=item F<log/*.log>

Log files. See L<Crane::Logger|Crane::Logger/"FILES">.

=item F<run/*.pid>

Script's PID file.

=back


=head1 BUGS

Please report any bugs or feature requests to
L<https://rt.cpan.org/Public/Bug/Report.html?Queue=Crane> or to
L<https://github.com/temoon/crane/issues>.


=head1 AUTHOR

Tema Novikov, <novikov.tema@gmail.com>


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013-2014 Tema Novikov.

This library is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0. For details, see the full text of the
license in the file LICENSE.


=head1 SEE ALSO

=over

=item * B<RT Cpan>

L<https://rt.cpan.org/Public/Dist/Display.html?Name=Crane>

=item * B<Github>

L<https://github.com/temoon/crane>

=back
