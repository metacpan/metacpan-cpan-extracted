package Apache::Language::DBI;
use Apache::Language::Constants;
use DBI;
use vars qw($VERSION);

$VERSION = '0.03';



sub modified {
    my ($class, $data, $cfg) = @_; 
    return undef;
}

sub store {
    my ($class, $data, $cfg, $key, $lang, $value) = @_;
    my ($rv, $sth);
    if (fetch($class, $data, $cfg, $key, $lang)){
        $sth = $cfg->{dbh}->prepare("update ".$cfg->{tablename}." set $cfg->{value}=? where $cfg->{key}=? and $cfg->{lang}=?");
        $rv = $sth->execute($value,$key,$lang);
    }
    else {
        $sth = $cfg->{dbh}->prepare("insert into ".$cfg->{tablename}."($cfg->{value},$cfg->{key},$cfg->{lang}) values (?,?,?)");
        $rv = $sth->execute($value,$key,$lang);
        }
    return L_OK if $rv;
    }

sub fetch {
        my ($class, $data, $cfg, $key, $variant) = @_;
        my @language;
        my $sth;
        
        unless ($variant) {
            $sth = $cfg->{dbh}->prepare("select $cfg->{lang} from ".$cfg->{tablename}." where $cfg->{key}=?") || return undef;
            if ($sth->execute($key)){
            while (my @row = $sth->fetchrow){
                $row[0] =~ s/\s+//;
                push @language, $row[0];
                }
            $variant = $data->best_lang(@language);
            }
            
        }

        return undef unless $variant;
        
        $sth = $cfg->{dbh}->prepare("select $cfg->{value} from ".$cfg->{tablename}." where $cfg->{key}=? and $cfg->{lang}=?") || return undef;
        $sth->execute($key,$variant);
        return $sth->fetchrow;	
}
   
sub firstkey {
    my ($class, $data, $cfg) = @_;
    $cfg->{listh} = $cfg->{dbh}->prepare("select distinct $cfg->{key} from ".$cfg->{tablename}." order by $cfg->{key}") || return undef;
    return undef unless $cfg->{listh}->execute;
    return $cfg->{listh}->fetchrow;
    } 

sub nextkey {
    my ($class, $data, $cfg, $key) = @_;
    return $cfg->{listh}->fetchrow;
    }
    
sub initialize {
            my ($self, $data, $cfg) = @_;
            my $r = $data->{Request};
            
			my $dbhfunc = $r->dir_config("Language::DBI::GetDBFunc");
            my $Datasource = $r->dir_config("Language::DBI::Datasource") || "DBI:Pg:dbname=apache;host=herge";
            my $username = $r->dir_config("Language::DBI::Username") || 'apache';
            my $password = $r->dir_config("Language::DBI::Password") || 'www';
            $cfg->{tablename} = $r->dir_config("Language::DBI::TableName") || 'language';
				
				$cfg->{key} 		= $r->dir_config("Language::DBI::TableKey") || 'key';
				$cfg->{lang} 		= $r->dir_config("Language::DBI::TableLang") || 'lang';
				$cfg->{value} 		= $r->dir_config("Language::DBI::TableValue") || 'value';
            
            if ($dbhfunc)
				{
				no strict 'refs';
				$cfg->{dbh} = &$dbhfunc();
				use strict 'refs';
				}
			else 
				{
				$cfg->{dbh} = DBI->connect($Datasource, $username, $password);
				}	
			
			if ($cfg->{dbh}){
                return L_OK;
                }
            else {
                warning("DBI initialization failed $DBI::errstr");
                return L_ERROR;
                }
}
1;
__END__

=head1 NAME

Apache::Language::DBI - DBI interface for Apache::Language

=head1 SYNOPSIS

 <Location /under/language/control/>
 PerlSetVar Language::DBI::Datasource  DBI:Pg:dbname=database;host=database.host
 PerlSetVar Language::DBI::Username webserver
 PerlSetVar Language::DBI::Password unguessable
 PerlSetVar Language::DBI::TableName language [default]
 Language::DBI::TableKey		key 	[column for the key]
 Language::DBI::TableLang		lang	[column for the lang]
 Language::DBI::TableValue 	value [column for the value]
 LanguageHandler Apache::Language::DBI
 </Location>

=head1 DESCRIPTION

This LanguageHandler implements a per-location DBI dictionnary.  It looks-up a given
table for a matching language/key pair and returns the best possible match.

The configurable directives are pretty self-explanatory.

=head1 TODO

Some sort of caching could be done.

=head1 SEE ALSO

perl(1), L<Apache>(3), L<Apache::Language>(3) L<Apache::Language::Constants>(3), and all L<Apache::Language::*>. 

=head1 SUPPORT

Please send any questions or comments to the Apache modperl 
mailing list <modperl@apache.org> or to me at <gozer@ectoplasm.dyndns.com>

=head1 NOTES

This code was made possible by :

=over

=item *

Doug MacEachern <dougm@pobox.com>  Creator of mod_perl.  That should mean enough.

=item *

Andreas Koenig <koenig@kulturbox.de> The one I got the idea from in the first place.

=item *

The mod_perl mailing-list at <modperl@apache.org> for all your mod_perl related problems.

=back

=head1 AUTHOR

Philippe M. Chiasson <gozer@ectoplasm.dyndns.com>

=head1 COPYRIGHT

Copyright (c) 1999 Philippe M. Chiasson. All rights reserved. This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself. 

=cut
