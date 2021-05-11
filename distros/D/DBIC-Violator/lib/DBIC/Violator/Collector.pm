package DBIC::Violator::Collector;

use strict;
use warnings;

# ABSTRACT: Collector object for DBIC::Violator

use Moo;
use Types::Standard qw(:all);
use Time::HiRes qw(gettimeofday tv_interval);
use Path::Class qw(file dir);

require SQL::Abstract::Tree;
use DBIC::Violator::Collector::DbConn;

use Plack::Util;
use Plack::Request;
use Plack::Response;

use RapidApp::Util ':all';

has 'DbConn', is => 'ro', lazy => 1, clearer => 1, default => sub {
  my $self = shift;
  DBIC::Violator::Collector::DbConn->new({ Collector => $self })
}, isa => InstanceOf['DBIC::Violator::Collector::DbConn'];

has 'application_name', is => 'ro', isa => Maybe[Str], default => sub { undef };

has 'log_db_dir',      is => 'ro', isa => Maybe[Str], default => sub { undef };
has 'log_db_file',     is => 'ro', isa => Maybe[Str], default => sub { undef };
has 'log_db_file_pfx', is => 'ro', isa => Str,        default => sub { 'dbic-violator-log_' };
has 'log_db_file_sfx', is => 'ro', isa => Str,        default => sub { '.db' };


has 'sqlat', is => 'ro', default => sub {
  SQL::Abstract::Tree->new({
    profile => 'console_monochrome',
    placeholder_surround => ['',''],
    newline => '',
    indent_string => ''
  });
};


has 'username_from_res_header', is => 'rw', isa => Maybe[Str], default => sub { undef };


sub BUILD {
  my $self = shift;
  $self->DbConn;
}


has '__pause_until_epoch', is => 'rw', isa => Maybe[Int], default => sub { undef };

sub pause_for {
  my ($self, $secs) = @_;
  $self->__pause_until_epoch(time + $secs);
}


sub paused {
  my $self = shift;
  
  if(my $epoch = $self->__pause_until_epoch) {
    if($epoch >= time) {
      return 1;
    }
    else {
      $self->__pause_until_epoch(undef);
    }
  }
  
  $self->logDbh ? 0 : 1
}

sub logDbh {
  my $self = shift;
   
  if ($self->DbConn->invalid) {
    $self->clear_DbConn;
    $self->DbConn->dbh;
    
    # If it comes back invalid again immediately:
    if ($self->DbConn->invalid) {
      $self->pause_for(5);
      $self->clear_DbConn;
      return undef;
    }
  }
  
  
  $self->DbConn->dbh
}




sub _middleware_call_coderef {
  my $self = shift;
  
  return sub {
    my ($mw, $env) = @_;
    return $mw->app->($env) if ($self->paused);
    
    my $start = [gettimeofday];
    
    $self->{_current_request_row_id} = undef;
    
    my $req = Plack::Request->new($env);
  
    my $reqRow = {
      start_ts     => scalar $start->[0],
      remote_addr  => scalar $req->address,
      uri          => scalar $req->uri->as_string,
      username     => scalar $req->user,
      method       => scalar $req->method,
      user_agent   => scalar $req->user_agent,
      referer      => scalar $req->referer
    };
    
    my $id = $self->_do_insert_request_row($reqRow);
    
    # Not able to localize this because of middleware internals, it goes
    # out of scope before we can use it:
    $self->{_current_request_row_id} = $id;
    
    my $res = $mw->app->($env);
    
    return Plack::Util::response_cb($res, sub {
      my $res = shift;  
      my $Res = Plack::Response->new(@$res);
 
      my $end = [gettimeofday];
      
      my $updates = {
        status            => scalar $Res->status,
        res_length        => scalar $Res->content_length,
        res_content_type  => scalar $Res->content_type,
        end_ts            => scalar $end->[0],
        elapsed_ms        => scalar int(1000 * tv_interval($start,$end))
      };
      
      if (my $user_header = $self->username_from_res_header) {
        $updates->{username} = $Res->header($user_header);
      }
      
      $self->{_current_request_row_id} = undef;
      $self->_do_update_request_row_by_id( $id => $updates );
    });
  }
}




sub _execute_around_coderef {
  my $self = shift;
  
  return sub {
    my ($orig, $pkg, $op, $ident, @args) = @_;
    return $pkg->$orig($op, $ident, @args) if ($self->paused);
    
    my $meta = { op => $op, ident => $ident };
    
    my $info = $pkg->_resolve_ident_sources($ident) || {};
    
    $meta->{rsrc} = $info->{me} if ($info->{me});

    local $self->{_currently_executing_meta} = $meta;
    
    $pkg->$orig($op, $ident, @args)
    
  };
}



sub _dbh_execute_around_coderef {
  my $self = shift;
  
  return sub {
    my ($orig, $pkg, @args) = @_;
    return $pkg->$orig(@args) if ($self->paused);
    
    my $start = [gettimeofday];
    
    my $logRow = {};
    
    $logRow->{unix_ts} = $start->[0];
    
    if(my $id = $self->{_current_request_row_id}) {
      $logRow->{request_id} = $id;
    }
    
    my $storage = $pkg;
    
    if(my $class = try{ref($storage->schema)}) {
      $logRow->{schema_class} = $class
    }
    
    if(my $driver = try{$storage->dbh->{Driver}{Name}}) {
      $logRow->{dbi_driver} = $driver;
    };
    
    if(my $cmeta = $self->{_currently_executing_meta}) {
      if (my $rsrc = $cmeta->{rsrc}) {
        $logRow->{source_name} = $cmeta->{rsrc}->source_name;
      }
      if (my $op = $cmeta->{op}) {
        $logRow->{operation} = $op; #$self->_resolve_op_type($op);
      }
    };
    
    my ($dbh, $sql, $bind, $bind_attrs) = @args;
    
    my @aRet = ();
    my $sRet = undef;
    
    my @fbind = $self->_format_for_trace($bind);
    $logRow->{statement} = $self->sqlat->format($sql,\@fbind);
    
    if(wantarray) {
      @aRet = $pkg->$orig(@args);
    }
    else {
      $sRet = $pkg->$orig(@args);
    }
    
    $logRow->{elapsed_ms} = int(1000 * tv_interval($start));
    
    $self->_do_insert_query_row($logRow);
    
    return wantarray ? @aRet : $sRet;
  };
}



sub _do_insert_query_row {
  my ($self, $row) = @_;
  
  my @colnames = keys %$row;
  
  my $insert = join('',
    'INSERT INTO [query] ',
    '(', join(',',map {"[$_]"} @colnames),') ',
    'VALUES (',join(',',map {'?'} @colnames),') '
  );
  
  my $sth = $self->logDbh->prepare($insert);
  
  $sth->execute(map { $row->{$_} } @colnames);
}



sub _do_insert_request_row {
  my ($self, $row) = @_;
  
  my @colnames = keys %$row;
  
  my $insert = join('',
    'INSERT INTO [request] ',
    '(', join(',',map {"[$_]"} @colnames),') ',
    'VALUES (',join(',',map {'?'} @colnames),') '
  );
  
  my $sth = $self->logDbh->prepare($insert);
  
  $sth->execute(map { $row->{$_} } @colnames);
  
  $self->logDbh->last_insert_id()
}


sub _do_update_request_row_by_id {
  my ($self, $id, $row) = @_;
  
  my @colnames = keys %$row;
  
  my $insert = join('',
    'UPDATE [request] ',
    'SET ', join(', ',map {"[$_] = ?"} @colnames),' ',
    'WHERE [id] = ' . $id
  );
  
  my $sth = $self->logDbh->prepare($insert);
  
  $sth->execute(map { $row->{$_} } @colnames);
}


# Copied from DBIx::Class::Storage::DBI
sub _format_for_trace {
  #my ($self, $bind) = @_;
 
  ### Turn @bind from something like this:
  ###   ( [ "artist", 1 ], [ \%attrs, 3 ] )
  ### to this:
  ###   ( "'1'", "'3'" )
 
  map {
    defined( $_ && $_->[1] )
      ? qq{'$_->[1]'}
      : q{NULL}
  } @{$_[1] || []};
}




1;


__END__

=head1 NAME

DBIC::Violator::Collector - Collector object for DBIC::Violator

=head1 DESCRIPTION

This is an internal object class used by L<DBIC::Violator> and should not be used directly.

=head1 SEE ALSO

=over

=item * 

L<DBIC::Violator>

=back


=head1 AUTHOR

Henry Van Styn <vanstyn@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by IntelliTree Solutions llc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut