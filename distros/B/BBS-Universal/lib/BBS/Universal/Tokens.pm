package BBS::Universal::Tokens;
BEGIN { our $VERSION = '0.001'; }

sub tokens_initialize {
	my $self = shift;

	$self->{'debug'}->DEBUG(['Begin Tokens initialize']);
	$self->{'TOKENS'} = {
        'AUTHOR NAME' => sub {
            my $self = shift;
            return ($self->{'CONF'}->{'STATIC'}->{'AUTHOR NAME'});
        },
        'BANNER' => sub {
            my $self   = shift;
            my $banner = $self->files_load_file('files/main/banner');
            return ($banner);
        },
        'BBS NAME' => sub {
            my $self = shift;
            return ($self->{'CONF'}->{'BBS NAME'});
        },
        'BBS VERSION'  => $self->{'VERSIONS'}->{'BBS Executable'},
        'BIRTHDAY' => sub {
            my $self = shift;
            my $birthday = $self->{'USER'}->{'birthday'};
            if (length($birthday) > 5) {
                $birthday =~ s/\d\d\d\d\-(\d+)\-(\d+)/${1}-${2}/;
            }
            return($birthday);
        },
        'BAUD RATE' => sub {
            my $self = shift;
            return ($self->{'baud_rate'});
        },
        'CPU IDENTITY' => $self->{'CPU'}->{'CPU IDENTITY'},
        'CPU CORES'    => $self->{'CPU'}->{'CPU CORES'},
        'CPU SPEED'    => $self->{'CPU'}->{'CPU SPEED'},
        'CPU THREADS'  => $self->{'CPU'}->{'CPU THREADS'},
        'FORTUNE' => sub {
            my $self = shift;
            return ($self->get_fortune);
        },
        'FILE CATEGORY' => sub {
            my $self = shift;
            return ($self->users_file_category());
        },
        'FORUM CATEGORY' => sub {
            my $self = shift;
            return ($self->news_title_colorize($self->users_forum_category()));
        },
        'LAST LOGIN' => sub {
            my $self = shift;
            return($self->{'USER'}->{'login_time'});
        },
        'LAST LOGOUT' => sub {
            my $self = shift;
            return($self->{'USER'}->{'logout_time'});
        },
        'NOW' => sub {
            my $self = shift;
            return($self->now());
        },
        'ONLINE' => sub {
            my $self = shift;
            return ($self->{'CACHE'}->get('ONLINE'));
        },
        'OS'           => $self->{'os'},
        'PERL VERSION' => $self->{'VERSIONS'}->{'Perl'},
        'RSS CATEGORY' => sub {
            my $self = shift;
            return ($self->news_title_colorize($self->users_rss_category()));
        },
        'SHOW USERS LIST' => sub {
            my $self = shift;
            return ($self->users_list());
        },
        'SYSOP'        => sub {
            my $self = shift;
            if ($self->{'sysop'}) {
                return ('SYSOP CREDENTIALS');
            } else {
                return ('USER CREDENTIALS');
            }
        },
        'THREAD ID' => sub {
            my $self = shift;
            my $tid  = threads->tid();
            if ($tid == 0) {
                $tid = 'LOCAL';
            } else {
                $tid = sprintf('%02d', $tid);
            }
            return ($tid);
        },
        'TIME' => sub {
            my $self = shift;
            return (DateTime->now);
        },
        'USER INFO' => sub {
            my $self = shift;
            return ($self->users_info());
        },
        'USER PERMISSIONS' => sub {
            my $self = shift;
            return ($self->dump_permissions);
        },
        'USER ID' => sub {
            my $self = shift;
            return ($self->{'USER'}->{'id'});
        },
        'USER FULLNAME' => sub {
            my $self = shift;
            return ($self->{'USER'}->{'fullname'});
        },
        'USER USERNAME' => sub {
            my $self = shift;
            if ($self->{'USER'}->{'prefer_nickname'}) {
                return ($self->{'USER'}->{'nickname'});
            } else {
                return ($self->{'USER'}->{'username'});
            }
        },
        'USER NICKNAME' => sub {
            my $self = shift;
            return ($self->{'USER'}->{'nickname'});
        },
        'USER EMAIL' => sub {
            my $self = shift;
            if ($self->{'USER'}->{'show_email'}) {
                return ($self->{'USER'}->{'email'});
            } else {
                return ('[HIDDEN]');
            }
        },
        'USERS COUNT' => sub {
            my $self = shift;
            return ($self->users_count());
        },
        'USER COLUMNS' => sub {
            my $self = shift;
            return ($self->{'USER'}->{'max_columns'});
        },
        'USER ROWS' => sub {
            my $self = shift;
            return ($self->{'USER'}->{'max_rows'});
        },
        'USER SCREEN SIZE' => sub {
            my $self = shift;
            return ($self->{'USER'}->{'max_columns'} . 'x' . $self->{'USER'}->{'max_rows'});
        },
        'USER GIVEN' => sub {
            my $self = shift;
            return ($self->{'USER'}->{'given'});
        },
        'USER FAMILY' => sub {
            my $self = shift;
            return ($self->{'USER'}->{'family'});
        },
        'USER LOCATION' => sub {
            my $self = shift;
            return ($self->{'USER'}->{'location'});
        },
        'USER BIRTHDAY' => sub {
            my $self = shift;
            return ($self->{'USER'}->{'birthday'});
        },
        'USER RETRO SYSTEMS' => sub {
            my $self = shift;
            return ($self->{'USER'}->{'retro_systems'});
        },
        'USER LOGIN TIME' => sub {
            my $self = shift;
            return ($self->{'USER'}->{'login_time'});
        },
        'USER TEXT MODE' => sub {
            my $self = shift;
            return ($self->{'USER'}->{'text_mode'});
        },
        'UPTIME' => sub {
            my $self = shift;
            chomp(my $uptime = `uptime -p`);
            $self->{'debug'}->DEBUG(["Get Uptime $uptime"]);
            return ($uptime);
        },
        'VERSIONS' => 'placeholder',
        'UPTIME'   => 'placeholder',
	};
	$self->{'debug'}->DEBUG(['End Tokens initialize']);
}
1;
