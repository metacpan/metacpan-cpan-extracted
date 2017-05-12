package Apache::HTMLView;

#  Apache::HTMLView.pm - Handling compiled HTMLView-fmt's as a
#                        mod_perl module in Apache 
#  (c) Copyright 2001 Bjorn Ardo <f98ba@efd.lth.se>
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  any later version.
#  
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#  
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

=head1 NAME

  Apache::HTMLView -  Handling compiled HTMLView-fmt's as a mod_perl module in Apache

=head1 VERSION

        $Revision: 0.91 $

=head1 SYNOPSIS

In httpd.conf:

 # HTMLView
 PerlSetVar name_fmtpath /var/www/fmt
 PerlSetVar name_DBIstr "DBI:mysql:dbname"
 PerlSetVar name_DBI_User "user"
 PerlSetVar name_DBI_Password "Password"


 # Load this after the vars are set
 PerlModule Apache::HTMLView

 <Location /fmt>
 PerlSetVar Name name
 SetHandler perl-script  
 PerlHandler Apache::HTMLView
 </Location>

=head1 DESCRIPTION

This module loads compiled fmt's from the dir name_fmtpath and runs
as a mod_perl module. It also loads all actions in that dir. It is 
possible to have many diffrent dirs with fmt's, just have diffrent
names for them: name1_fmtpath, name2_fmtpath...

This module uses Apache::DBI to cache database connections and evals
fmt's and actions at startup. All to inprove speed.

For information about actions and fmt's, see DBIx::HTMLView.

=cut

use vars qw( $VERSION );
( $VERSION ) = '$Revision: 0.91 $' =~ /([\d.]+)/;


use Apache::DBI;
use DBI;
use CGI;

use Apache::Constants qw(OK DECLINED REDIRECT);
use vars qw(%actionlist %actions %fmtlist %fmts );


##############################################################
# The fake sth, used to add new elements with empty defaults #
##############################################################

{
package fake_sth;

  sub new {
   my $this = shift;
   my $class = ref($this) || $this;
   my $self=       bless {}, $class;
  }
  
  sub execute 
   {shift->{'first'}=1}

  sub fetchrow_arrayref {
   my ($self)=@_;
   if ($self->{'first'}) {
     $self->{'first'}=0;
     $a[0]='';
     return \@a;
   }
   return [];
  }

}


#############################################################
# The handler, this parses the request and returns the page #
#############################################################

sub handler {
 my $r = shift;

## Determine which fmt_dir to use

 %actions = %{$actionlist{$r->dir_config('Name')}};
 %fmts = %{$fmtlist{$r->dir_config('Name')}};

## Reading request params
 my $uri = $r->uri;
 $uri =~ /\/([^\/]*)$/;
 $file = $1; 
 my $q = new CGI();


 ## Make buttonspecifik param overrides overide the defaults
   if (defined $q->param('_but') && defined $q->param('_but_'.$q->param('_but'))){
     my $oq=new CGI($q->param('_but_'.$q->param('_but')));
     foreach ($oq->param) {
       $q->param($_, $oq->param($_));
     }
   }


 ## Execute requst action
 if (defined $q && defined $q->param('_pre_action')) {
     $actions{$q->param('_pre_action')}->($q, $r) 
     }
   
   
 ## Update database if requested
 if (defined $actions{$file}) {
     $actions{$file}->($q,$r); 
     
     ## Decide what to show next
     $file=$q->param('_done'); 
     if (!defined $file || lc($file) eq 'ref') {$file=$r->headers_in->{'Referer'};}

     ## Send client to that fmt
     $r->header_out(Location=>$file);
     return REDIRECT;
 } else {
     ## Bring up requested fmt

     my @sel;
#     if (defined $q) {@sel=split(/,\s*/,$q->param('sel'));}
     if (defined $q) {@sel=$q->param('sel');}
     if (defined $fmts{$file}) {
	 $r->content_type('text/html');
	 $r->send_http_header;
	 $r->print($fmts{$file}->(\@sel, $q, $r));
	 return OK;
     } else {
	 # Let someone else handle the request
	 return DECLINED;
     }
 }

}

########################
# Reading all fmt-dirs #
########################

BEGIN {
    
    # Finding all dirs
    my @fmt_dirs = grep {
	$_ =~ /_fmtpath$/
        } keys %{ Apache->server->dir_config() };

    my $fsth=fake_sth->new();
        

    foreach my $fmt_dir ( @fmt_dirs ) {
	my $fmtdir = Apache->server->dir_config( $fmt_dir );
	my $fmtname = $fmt_dir;
	$fmtname =~ s/_fmtpath$//;
	
	my $dbistr = Apache->server->dir_config($fmtname . "_DBIstr");
	my $dbiuser = Apache->server->dir_config($fmtname . "_DBI_User");
	my $dbipasswd = Apache->server->dir_config($fmtname . "_DBI_Password");

	# Making sure the DB exsists and caching a handle to it
	DBI->connect($dbistr, $dbiuser, $dbipasswd)->disconnect();


	# Load the compiled fmts and the htmlfile
	# Maby use Apache::File ??????
	foreach (`ls $fmtdir/*`) 
	{

	    # Reading the file
	    chop;
	    my $name= $_ ;
	    my $filename = $name;
	    my $con= '' ;


	    $name=~s/^.*\/([^\/]+)$/$1/;
	    
	    if ($name !~ /\~$/) {
		# An action
		if ($name =~ /^\_/) {
		    open(F, "<$filename");
		    while (<F>) {$con.=$_;}
		    close(F);

		    my $act=eval($con);
		    warn $@ if ($@);
		    
		    # Adding the action
		    $actionlist{$fmtname}->{$name}= sub { $act->(DBI->connect($dbistr, $dbiuser, $dbipasswd), @_); };
		} 
		# An fmt
		elsif ($name =~ /.cfmt$/) {
		    open(F, "<$filename");
		    while (<F>) {$con.=$_;}
		    close(F);

		    $name =~ s/.cfmt$//;
		    my $fmt = eval($con);
		    warn $@ if ($@);

		    # Adding the fmt and an empty one
		    if (defined $fmt->[2])
		    {
		      $fmtlist{$fmtname}->{$name} = sub { my $dbi = DBI->connect($dbistr, $dbiuser, $dbipasswd); my $sth = $dbi->prepare($fmt->[0]);  my @in = @_; unshift (@{$in[0]}, $in[2]->connection->user); $fmt->[1]->($dbi, $sth, @in); };
		    }
		    else
		    {
  		      $fmtlist{$fmtname}->{$name} = sub { my $dbi = DBI->connect($dbistr, $dbiuser, $dbipasswd); my $sth = $dbi->prepare($fmt->[0]); $fmt->[1]->($dbi, $sth, @_); };
		    }


		    $fmtlist{$fmtname}->{'_new_'.$name} = sub { $fmt->[1]->(DBI->connect($dbistr, $dbiuser, $dbipasswd), $fsth, @_ ); };
		}
	    }
	}
    
    
    }
}



1;
