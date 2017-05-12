NAME
    Cisco::IronPort - Interface to Cisco IronPort Reporting API

SYNOPSIS
            use Cisco::IronPort;

            my $ironport = Cisco::IronPort->new(
                    username => $username,
                    password => $password,
                    server   => $server
            );

            my %stats = $ironport->incoming_mail_summary_current_hour;

            print "Total Attempted Messages : $stats{total_attempted_messages}{count}\n";
            print "Clean Messages : $stats{clean_messages}{count} ($stats{clean_messages}{percent}%)\n";

            # prints...
            # Total Attempted Messages : 932784938
            # Clean Messages : (34%) 

            # Print the destination domain and number of pending messages for any domain 
            # with > 50 pending messages

            foreach my $domain ( keys %stats ) { 
                    print "There are $stats{$domain}{active_recipients} pending message for $domain\n"
                            if ( $stats{$domain}{active_recipients} > 50  
                                    and $stats{$domain}{latest_host_status} ne 'Down' )
            }

            # Call an alert() function for any users whom have sent mail that matched an outgoing content filter -
            # handy to warn of users whom have sent mail to a known phishing address.

            foreach my $user ( keys %users ) { 
                    alert("$user had $users{$user}{outgoing_stopped_by_content_filter} matches for outgoing content filters") 
                            if $users{$user}{outgoing_stopped_by_content_filter}
            }

METHODS
   new ( %ARGS )
            my $ironport = Cisco::IronPort->new(
                    username => $username,
                    password => $password,
                    server   => $server
            );

    Creates a Cisco::IronPort object. The constructor accepts a hash
    containing three mandatory and one optional parameter.

    username
       The username of a user authorised to access the reporting API.

    password
       The password of the username used to access the reporting API.

    server
       The target IronPort device hosting the reporting API. This value must
       be either a resolvable hostname or an IP address.

    proto
       This optional parameter may be used to specify the protocol (either
       http or https) which should be used when connecting to the reporting
       API. If unspecified this parameter defaults to https.

   incoming_mail_summary_current_hour
            my %stats = $ironport->incoming_mail_summary_current_hour;
            print "Total Attempted Messages : $stats{total_attempted_messages}{count}\n";

    Returns a nested hash containing incoming mail summary statistics for
    the current hourly period. The hash has the structure show below:

            $stats = {
              'statistic_name_1' => {
                'count'   => $count,
                'percent' => $percent
              },
              'statistic_name_2' => {
                'count'   => $count,
                'percent' => $percent
              },
              ...

              'statistic_name_n => {
                ...
              }

    Valid statistic names are show below - these names are derived from
    those returned by the reporting API with all spaces converted to
    underscores and all characters lower-cased.

            stopped_by_reputation_filtering 
            stopped_as_invalid_recipients 
            stopped_by_content_filter 
            total_attempted_messages 
            total_threat_messages 
            clean_messages 
            virus_detected
            spam_detected

   incoming_mail_summary_current_day
    Returns a nested hash with the same structure and information as
    described above for the incoming_mail_summary_current_hour method, but
    for a time period covering the current day.

   incoming_mail_summary_current_week
    Returns a nested hash with the same structure and information as
    described above for the incoming_mail_summary_current_hour method, but
    for a time period covering the current week.

   incoming_mail_summary_current_hour_raw
    Returns a scalar containing the incoming mail summary statistics for the
    current hour period unformated and as retrieved directly from the
    reporting API.

    This method may be useful if you wish to process the raw data from the
    API call directly.

   incoming_mail_summary_current_day_raw
    Returns a scalar containing the incoming mail summary statistics for the
    current day period unformated and as retrieved directly from the
    reporting API.

    This method may be useful if you wish to process the raw data from the
    API call directly.

   incoming_mail_summary_current_week_raw
    Returns a scalar containing the incoming mail summary statistics for the
    current week period unformated and as retrieved directly from the
    reporting API.

   incoming_mail_details_current_hour
            # Print a list of sending domains which have sent more than 50 messages
            # of which over 50% were detected as spam.

            my %stats = $ironport->incoming_mail_details_current_hour;
        
            foreach my $domain (keys %stats) {
              if ( ( $stats{$domain}{total_attempted} > 50 ) and 
                   ( int (($stats{$domain}{spam_detected}/$stats{$domain}{total_attempted})*100) > 50 ) {
                print "Domain $domain sent $stats{$domain}{total_attempted} messages, $stats{$domain}{spam_detected} were marked as spam.\n"
              }
            }

    Returns a nested hash containing details of incoming mail statistics for
    the current hour period. The hash has the following structure:

            sending.domain1.com => {
              begin_date                            => a human-readable timestamp at the beginning of the measurement interval (YYYY-MM-DD HH:MM TZ),
              begin_timestamp                       => seconds since epoch at the beginning of the measurement interval (resolution of 100ms),
              clean                                 => total number of clean messages sent by this domain,
              connections_accepted                  => total number of connections accepted from this domain,
              end_date                              => a human-readable timestamp at the end of the measurement interval (YYYY-MM-DD HH:MM TZ),
              end_timestamp                         => seconds since epoch at the end of the measurement interval (resolution of 100ms),
              orig_value                            => the domain name originally establishing the connection prior to any relaying or masquerading,
              sender_domain                         => the sending domain,
              spam_detected                         => the number of messages marked as spam from this domain,
              stopped_as_invalid_recipients         => number of messages stopped from this domain due to invalid recipients,
              stopped_by_content_filter             => number of messages stopped from this domain due to content filtering,
              stopped_by_recipient_throttling       => number of messages stopped from this domain due to recipient throttling,
              stopped_by_reputation_filtering       => number of messages stopped from this domain due to reputation filtering,
              total_attempted                       => total number of messages sent from this domain,
              total_threat                          => total number of messages marked as threat messages from this domain,
              virus_detected                        => total number of messages marked as virus positive from this domain
            },
            sending.domain2.com => {
              ...
            },
            ...
            sending.domainN.com => {
              ...
            }

    Where each domain having sent email in the current hour period is used
    as the value of a hash key in the returned hash having the subkeys
    listed above. For a busy device this hash may contain hundreds or
    thousands of domains so caution should be excercised in storing and
    parsing this structure.

   incoming_mail_details_current_day
    This method returns a nested hash as described in the
    incoming_mail_details_current_hour method above but for a period of the
    current day. Consequently the returned hash may contain a far larger
    number of entries.

   incoming_mail_details_current_week
    This method returns a nested hash as described in the
    incoming_mail_details_current_hour method above but for a period of the
    current week. Consequently the returned hash may contain a far larger
    number of entries.

   incoming_mail_details_current_hour_raw
    Returns a scalar containing the incoming mail details for the current
    hour period as retrieved directly from the reporting API. This method is
    useful is you wish to access and/or parse the results directly.

   incoming_mail_details_current_day_raw
    Returns a scalar containing the incoming mail details for the current
    day period as retrieved directly from the reporting API. This method is
    useful is you wish to access and/or parse the results directly.

   incoming_mail_details_current_week_raw
    Returns a scalar containing the incoming mail details for the current
    week period as retrieved directly from the reporting API. This method is
    useful is you wish to access and/or parse the results directly.

   top_users_by_clean_outgoing_messages_current_hour
            # Print a list of our top internal users and number of messages sent.
        
            my %top_users = $ironport->top_users_by_clean_outgoing_messages_current_hour;

            foreach my $user (sort keys %top_users) {
              print "$user - $top_users{clean_messages} messages\n";
            }

    Returns a nested hash containing details of the top ten internal users
    by number of clean outgoing messages sent for the current hour period.
    The hash has the following structure:

            'user1@domain.com' => {
              begin_date            => a human-readable timestamp of the begining of the current hour period ('YYYY-MM-DD HH:MM TZ'),
              begin_timestamp       => a timestamp of the beginning of the current hour period in seconds since epoch,
              end_date              => a human-readable timestamp of the end of the current hour period ('YYYY-MM-DD HH:MM TZ'),
              end_timestamp         => a timestamp of the end of the current hour period in seconds since epoch,
              internal_user         => the email address of the user (this may also be 'unknown user' if the address cannot be determined),
              clean_messages        => the number of clean messages sent by this user for the current hour period
            },
            'user2@domain.com' => {
              ...
            },
            ...
            user10@domain.com' => {
              ...
            }

   top_users_by_clean_outgoing_messages_current_day
    Returns a nested hash containing details of the top ten internal users
    by number of clean outgoing messages sent for the current day period.

   top_users_by_clean_outgoing_messages_current_week
    Returns a nested hash containing details of the top ten internal users
    by number of clean outgoing messages sent for the current week period.

   top_users_by_clean_outgoing_messages_current_hour_raw
    Returns a scalar containing the details of the top ten internal users by
    number of clean outgoing messages sent for the current hour period as
    retrieved directly from the reporting API.

    This method may be useful if you wish to process the raw data retrieved
    from the API yourself.

   top_users_by_clean_outgoing_messages_current_day_raw
    Returns a scalar containing the details of the top ten internal users by
    number of clean outgoing messages sent for the current day period as
    retrieved directly from the reporting API.

    This method may be useful if you wish to process the raw data retrieved
    from the API yourself.

   top_users_by_clean_outgoing_messages_current_week_raw
    Returns a scalar containing the details of the top ten internal users by
    number of clean outgoing messages sent for the current week period as
    retrieved directly from the reporting API.

   average_time_in_workqueue_current_hour
            my %stats = $ironport->average_time_in_workqueue_current_day;
        
            foreach my $i (sort keys %stats) {
                    print "$stats{$i}{end_date} : $stats{$i}{time}\n"
            }
        
            # Prints the average time a message spent in the workqueue for the current hourly period
            # e.g.
            # 2012-08-07 03:34 GMT : 1.76650943396
            # 2012-08-07 03:39 GMT : 4.97411003236
            # 2012-08-07 03:44 GMT : 0.955434782609
            # 2012-08-07 03:49 GMT : 3.38574040219
            # 2012-08-07 03:54 GMT : 2.32837301587
            # ...

    This method returns a nested hash containing statistics for the average
    time a message spent in the workqueue for the previous hourly period -
    the hash has the following structure:

            measurement_period_1_begin_timestamp => {
              begin_timestamp       => a timestamp marking the beginning of the measurement period in seconds since epoch,
              end_timestamp         => a timestamp marking the ending of the measurement period in seconds since epoch,
              begin_date            => a human-readable timestamp marking the beginning of the measurement period (YYYY-MM-DD HH:MM:SS TZ),
              end_date              => a human-readable timestamp marking the ending of the measurement period (YYYY-MM-DD HH:MM:SS TZ),
              time                  => the average time in seconds a message spent in the workqueue for the measurement period
            },
            measurement_period_2_begin_timestamp => {
              ...
            },
            ...
            measurement_period_n_begin_timestamp => {
              ...
            }

   average_time_in_workqueue_current_day
    Returns a nested hash containing statistics for the average time a
    message spent in the workqueue for the previous daily period - the hash
    has the same structure as detailed in the
    average_time_in_workqueue_current_hour above.

   average_time_in_workqueue_current_week
    Returns a nested hash containing statistics for the average time a
    message spent in the workqueue for the previous weekly period - the hash
    has the same structure as detailed in the
    average_time_in_workqueue_current_hour above.

   average_time_in_workqueue_current_hour_raw
    Returns a scalar containing statistics for the average time a message
    spent in the workqueue for the previous hourly period as retrieved
    directly from the reporting API.

    This method may be useful if you wish to process the raw data retrieved
    from the API yourself.

   average_time_in_workqueue_current_day_raw
    Returns a scalar containing statistics for the average time a message
    spent in the workqueue for the previous daily period as retrieved
    directly from the reporting API.

    This method may be useful if you wish to process the raw data retrieved
    from the API yourself.

   average_time_in_workqueue_current_week_raw
    Returns a scalar containing statistics for the average time a message
    spent in the workqueue for the previous weekly period as retrieved
    directly from the reporting API.

   average_incoming_message_size_current_hour
            my %avg_msg_size = $ironport->average_incoming_message_size_current_hour;

            foreach my $mdata (sort keys %avg_msg_size) {
                    print "$avg_msg_size{$mdata}{end_date} : $avg_msg_size{$mdata}{message_size}\n";
            }

            # Prints the average incoming message size in bytes for the time sample periods in the previous hour.
            # e.g.
            # 2012-09-13 22:04 GMT : 111587.886555
            # 2012-09-13 22:09 GMT : 84148.6127168
            # 2012-09-13 22:14 GMT : 26486.8187919
            # 2012-09-13 22:19 GMT : 58772.1949153
            # ...

    This method returns a nested hash containing statistics for the average
    incoming message size in bytes for the previous hourly period - the hash
    has the following structure:

            measurement_period_1_begin_timestamp => {
              begin_timestamp       => a timestamp marking the beginning of the measurement period in seconds since epoch,
              end_timestamp         => a timestamp marking the ending of the measurement period in seconds since epoch,
              begin_date            => a human-readable timestamp marking the beginning of the measurement period (YYYY-MM-DD HH:MM:SS TZ),
              end_date              => a human-readable timestamp marking the ending of the measurement period (YYYY-MM-DD HH:MM:SS TZ),
              message_size          => the average incoming message size in bytes for the measurement period
            },
            measurement_period_2_begin_timestamp => {
              ...
            },
            ...
            measurement_period_n_begin_timestamp => {
              ...
            }

   average_incoming_message_size_current_day
    Returns a nested hash containing statistics for the average incoming
    message size in bytes for the previous daily period - the hash has the
    same structure as detailed in the
    average_incoming_message_size_current_hour above.

   average_incoming_message_size_current_week
    Returns a nested hash containing statistics for the average incoming
    message size in bytes for the previous weekly period - the hash has the
    same structure as detailed in the
    average_incoming_message_size_current_hour above.

    This method may be useful if you wish to process the raw data retrieved
    from the API yourself.

   average_incoming_message_size_current_hour_raw
    Returns a scalar containing statistics for the average incoming message
    size in bytes for the previous hourly period as retrieved directly from
    the reporting API.

   average_incoming_message_size_current_day_raw
    Returns a scalar containing statistics for the average incoming message
    size in bytes for the previous daily period as retrieved directly from
    the reporting API.

    This method may be useful if you wish to process the raw data retrieved
    from the API yourself.

   average_incoming_message_size_current_week_raw
    Returns a scalar containing statistics for the average incoming message
    size in bytes for the previous weekly period as retrieved directly from
    the reporting API.

   average_messages_in_workqueue_current_hour
    This method returns a nested hash containing statistics for the average
    number of messages in the workqueue for the previous hourly period - the
    hash has the following structure:

            measurement_period_1_begin_timestamp => {
              begin_timestamp       => a timestamp marking the beginning of the measurement period in seconds since epoch,
              end_timestamp         => a timestamp marking the ending of the measurement period in seconds since epoch,
              begin_date            => a human-readable timestamp marking the beginning of the measurement period (YYYY-MM-DD HH:MM:SS TZ),
              end_date              => a human-readable timestamp marking the ending of the measurement period (YYYY-MM-DD HH:MM:SS TZ),
              messages              => the average number of messages in the workqueue for the measurement period
            },
            measurement_period_2_begin_timestamp => {
              ...
            },
            ...
            measurement_period_n_begin_timestamp => {
              ...
            }

   average_messages_in_workqueue_current_day
    Returns a nested hash containing statistics for the average number of
    messages in the workqueue for the previous daily period - the hash has
    the same structure as detailed in the
    average_messages_in_workqueue_current_hour above.

   average_messages_in_workqueue_current_week
    Returns a nested hash containing statistics for the average number of
    messages in the workqueue for the previous weekly period - the hash has
    the same structure as detailed in the
    average_messages_in_workqueue_current_hour above.

   average_messages_in_workqueue_current_hour_raw
    Returns a scalar containing statistics for the average number of
    messages in the workqueue for the previous hourly period as retrieved
    directly from the reporting API.

    This method may be useful if you wish to process the raw data retrieved
    from the API yourself.

   average_messages_in_workqueue_current_day_raw
    Returns a scalar containing statistics for the average number of
    messages in the workqueue for the previous daily period as retrieved
    directly from the reporting API.

    This method may be useful if you wish to process the raw data retrieved
    from the API yourself.

   average_messages_in_workqueue_current_week_raw
    Returns a scalar containing statistics for the average number of
    messages in the workqueue for the previous weekly period as retrieved
    directly from the reporting API.

    This method may be useful if you wish to process the raw data retrieved
    from the API yourself.

   average_outgoing_message_size_current_hour
    This method returns a nested hash containing statistics for the average
    outgoing message size in bytes for the previous hourly period - the hash
    has the following structure:

            measurement_period_1_begin_timestamp => {
              begin_timestamp       => a timestamp marking the beginning of the measurement period in seconds since epoch,
              end_timestamp         => a timestamp marking the ending of the measurement period in seconds since epoch,
              begin_date            => a human-readable timestamp marking the beginning of the measurement period (YYYY-MM-DD HH:MM:SS TZ),
              end_date              => a human-readable timestamp marking the ending of the measurement period (YYYY-MM-DD HH:MM:SS TZ),
              message_size          => the average outgoing message size in bytes for the measurement period
            },
            measurement_period_2_begin_timestamp => {
              ...
            },
            ...
            measurement_period_n_begin_timestamp => {
              ...
            }

   average_outgoing_message_size_current_day
    Returns a nested hash containing statistics for the average outgoing
    message size in bytes for the previous daily period - the hash has the
    same structure as detailed in the
    average_outoging_message_size_current_hour above.

   average_outgoing_message_size_current_week
    Returns a nested hash containing statistics for the average outgoing
    message size in bytes for the previous weekly period - the hash has the
    same structure as detailed in the
    average_outoging_message_size_current_hour above.

   average_outgoing_message_size_current_hour_raw
    Returns a scalar containing statistics for the average outgoing message
    size in bytes for the previous hourly period as retrieved directly from
    the reporting API.

    This method may be useful if you wish to process the raw data retrieved
    from the API yourself.

   average_outgoing_message_size_current_day_raw
    Returns a scalar containing statistics for the average outgoing message
    size in bytes for the previous daily period as retrieved directly from
    the reporting API.

    This method may be useful if you wish to process the raw data retrieved
    from the API yourself.

   average_outgoing_message_size_current_week_raw
    Returns a scalar containing statistics for the average outgoing message
    size in bytes for the previous weekly period as retrieved directly from
    the reporting API.

    This method may be useful if you wish to process the raw data retrieved
    from the API yourself.

   cpu_by_function_current_hour
    This method returns a nested hash containing statistics for the CPU
    usage by function for the previous hourly period - the hash has the
    following structure:

            measurement_period_1_begin_timestamp => {
              begin_timestamp       => a timestamp marking the beginning of the measurement period in seconds since epoch,
              end_timestamp         => a timestamp marking the ending of the measurement period in seconds since epoch,
              begin_date            => a human-readable timestamp marking the beginning of the measurement period (YYYY-MM-DD HH:MM:SS TZ),
              end_date              => a human-readable timestamp marking the ending of the measurement period (YYYY-MM-DD HH:MM:SS TZ),
              anti-spam             => the percentage of CPU time used for anti-spam functions,
              anti-virus            => the percentage of CPU time used for anti-virus functions,
              mail_processing       => the percentage of CPU time used for mail processing functions,
              reporting             => the percentage of CPU time used for reporting functions,
              quarantine            => the percentage of CPU time used for quarantine functions,
            },
            measurement_period_2_begin_timestamp => {
              ...
            },
            ...
            measurement_period_n_begin_timestamp => {
              ...
            }

   cpu_by_function_current_day
    Returns a nested hash containing statistics for the CPU usage by
    function for the previous daily period - the hash has the same structure
    as detailed in the cpu_by_function_current_hour above.

   cpu_by_function_current_week
    Returns a nested hash containing statistics for the CPU usage by
    function for the previous weekly period - the hash has the same
    structure as detailed in the cpu_by_function_current_hour above.

   cpu_by_function_current_hour_raw
    Returns a scalar containing statistics for the CPU usage by function for
    the previous hourly period as retrieved directly from the reporting API.

    This method may be useful if you wish to process the raw data retrieved
    from the API yourself.

   cpu_by_function_current_day_raw
    Returns a scalar containing statistics for the CPU usage by function for
    the previous daily period as retrieved directly from the reporting API.

    This method may be useful if you wish to process the raw data retrieved
    from the API yourself.

   cpu_by_function_current_week_raw
    Returns a scalar containing statistics for the CPU usage by function for
    the previous weekly period as retrieved directly from the reporting API.

   incoming_content_filter_matches_current_hour
    This method returns a nested hash containing statistics for incoming
    content filter matches for the previous hourly period - the hash has the
    following structure:

            measurement_period_1_begin_timestamp => {
              begin_timestamp       => a timestamp marking the beginning of the measurement period in seconds since epoch,
              end_timestamp         => a timestamp marking the ending of the measurement period in seconds since epoch,
              begin_date            => a human-readable timestamp marking the beginning of the measurement period (YYYY-MM-DD HH:MM:SS TZ),
              end_date              => a human-readable timestamp marking the ending of the measurement period (YYYY-MM-DD HH:MM:SS TZ),
              content_filter        => the name of the content filter,
              messages              => the number of incoming messages matched by the content filter in the previous hour period,
              total_outgoing_matches=> the number of outgoing messages matched by the content filter in the previous hour period,
            },
            measurement_period_2_begin_timestamp => {
              ...
            },
            ...
            measurement_period_n_begin_timestamp => {
              ...
            }

   incoming_content_filter_matches_current_day
    Returns a nested hash containing statistics for incoming content filter
    matches for the previous daily period - the hash has the same structure
    as detailed in the incoming_content_filter_matches_current_hour above.

   incoming_content_filter_matches_current_week
    Returns a nested hash containing statistics for incoming content filter
    matches for the previous weekly period - the hash has the same structure
    as detailed in the incoming_content_filter_matches_current_hour above.

   incoming_content_filter_matches_current_hour_raw
    Returns a scalar containing statistics for incoming content filter
    matches for the previous hourly period as retrieved directly from the
    reporting API.

    This method may be useful if you wish to process the raw data retrieved
    from the API yourself.

   incoming_content_filter_matches_current_day_raw
    Returns a scalar containing statistics for the incoming content filter
    matches for the previous daily period as retrieved directly from the
    reporting API.

    This method may be useful if you wish to process the raw data retrieved
    from the API yourself.

   incoming_content_filter_matches_current_week_raw
    Returns a scalar containing statistics for the incoming content filter
    matches for the previous weekly period as retrieved directly from the
    reporting API.

    This method may be useful if you wish to process the raw data retrieved
    from the API yourself.

   outgoing_content_filter_matches_current_hour
    This method returns a nested hash containing statistics for outgoing
    content filter matches for the previous hourly period - the hash has the
    following structure:

            measurement_period_1_begin_timestamp => {
              begin_timestamp       => a timestamp marking the beginning of the measurement period in seconds since epoch,
              end_timestamp         => a timestamp marking the ending of the measurement period in seconds since epoch,
              begin_date            => a human-readable timestamp marking the beginning of the measurement period (YYYY-MM-DD HH:MM:SS TZ),
              end_date              => a human-readable timestamp marking the ending of the measurement period (YYYY-MM-DD HH:MM:SS TZ),
              content_filter        => the name of the content filter,
              messages              => the number of outgoing messages matched by the content filter in the previous hour period,
            },
            measurement_period_2_begin_timestamp => {
              ...
            },
            ...
            measurement_period_n_begin_timestamp => {
              ...
            }

   outgoing_content_filter_matches_current_day
    Returns a nested hash containing statistics for outgoing content filter
    matches for the previous daily period - the hash has the same structure
    as detailed in the outgoing_content_filter_matches_current_hour above.

   outgoing_content_filter_matches_current_week
    Returns a nested hash containing statistics for outgoing content filter
    matches for the previous weekly period - the hash has the same structure
    as detailed in the outgoing_content_filter_matches_current_hour above.

   outgoing_content_filter_matches_current_hour_raw
    Returns a scalar containing statistics for outgoing content filter
    matches for the previous hourly period as retrieved directly from the
    reporting API.

    This method may be useful if you wish to process the raw data retrieved
    from the API yourself.

   outgoing_content_filter_matches_current_day_raw
    Returns a scalar containing statistics for the outgoing content filter
    matches for the previous daily period as retrieved directly from the
    reporting API.

    This method may be useful if you wish to process the raw data retrieved
    from the API yourself.

   outgoing_content_filter_matches_current_week_raw
    Returns a scalar containing statistics for the outgoing content filter
    matches for the previous weekly period as retrieved directly from the
    reporting API.

    This method may be useful if you wish to process the raw data retrieved
    from the API yourself.

   maximum_messages_in_workqueue_current_hour
    This method returns a nested hash containing statistics for the maximum
    number of messages in the workqueue for the previous hourly period - the
    hash has the following structure:

            measurement_period_1_begin_timestamp => {
              begin_timestamp       => a timestamp marking the beginning of the measurement period in seconds since epoch,
              end_timestamp         => a timestamp marking the ending of the measurement period in seconds since epoch,
              begin_date            => a human-readable timestamp marking the beginning of the measurement period (YYYY-MM-DD HH:MM:SS TZ),
              end_date              => a human-readable timestamp marking the ending of the measurement period (YYYY-MM-DD HH:MM:SS TZ),
              messages              => the maximum number of messages in the workqueue for the measurement period
            },
            measurement_period_2_begin_timestamp => {
              ...
            },
            ...
            measurement_period_n_begin_timestamp => {
              ...
            }

   maximum_messages_in_workqueue_current_day
    Returns a nested hash containing statistics for the maximum number of
    messages in the workqueue for the previous daily period - the hash has
    the same structure as detailed in the
    maximum_messages_in_workqueue_current_hour above.

   maximum_messages_in_workqueue_current_week
    Returns a nested hash containing statistics for the maximum number of
    messages in the workqueue for the previous weekly period - the hash has
    the same structure as detailed in the
    maximum_messages_in_workqueue_current_hour above.

   maximum_messages_in_workqueue_current_hour_raw
    Returns a scalar containing statistics for the maximum number of
    messages in the workqueue for the previous hourly period as retrieved
    directly from the reporting API.

    This method may be useful if you wish to process the raw data retrieved
    from the API yourself.

   maximum_messages_in_workqueue_current_day_raw
    Returns a scalar containing statistics for the maximum messages in the
    workqueue for the previous daily period as retrieved directly from the
    reporting API.

    This method may be useful if you wish to process the raw data retrieved
    from the API yourself.

   maximum_messages_in_workqueue_current_week_raw
    Returns a scalar containing statistics for the maximum messages in the
    workqueue for the previous weekly period as retrieved directly from the
    reporting API.

    This method may be useful if you wish to process the raw data retrieved
    from the API yourself.

   memory_page_swapping_current_hour
    This method returns a nested hash containing statistics for the number
    of memory pages swapped for the previous hourly period - the hash has
    the following structure:

            measurement_period_1_begin_timestamp => {
              begin_timestamp       => a timestamp marking the beginning of the measurement period in seconds since epoch,
              end_timestamp         => a timestamp marking the ending of the measurement period in seconds since epoch,
              begin_date            => a human-readable timestamp marking the beginning of the measurement period (YYYY-MM-DD HH:MM:SS TZ),
              end_date              => a human-readable timestamp marking the ending of the measurement period (YYYY-MM-DD HH:MM:SS TZ),
              pages_swapped         => the number of memory pages swapped for the measurement period
            },
            measurement_period_2_begin_timestamp => {
              ...
            },
            ...
            measurement_period_n_begin_timestamp => {
              ...
            }

   memory_page_swapping_current_day
    Returns a nested hash containing statistics for the number of memory
    pages swapped for the previous daily period - the hash has the same
    structure as detailed in the memory_page_swapping_current_hour above.

   memory_page_swapping_current_week
    Returns a nested hash containing statistics for the number of memory
    pages swapped for the previous weekly period - the hash has the same
    structure as detailed in the memory_page_swapping_current_hour above.

   memory_page_swapping_current_hour_raw
    Returns a scalar containing statistics for the number of memory pages
    swapped for the previous hourly period as retrieved directly from the
    reporting API.

    This method may be useful if you wish to process the raw data retrieved
    from the API yourself.

   memory_page_swapping_current_day_raw
    Returns a scalar containing statistics for the number of memory pages
    swapped for the previous daily period as retrieved directly from the
    reporting API.

    This method may be useful if you wish to process the raw data retrieved
    from the API yourself.

   memory_page_swapping_current_week_raw
    Returns a scalar containing statistics for the number of memory pages
    swapped for the previous weekly period as retrieved directly from the
    reporting API.

    This method may be useful if you wish to process the raw data retrieved
    from the API yourself.

   overall_cpu_usage_current_hour
    This method returns a nested hash containing statistics for the overall
    CPU usage for the previous hourly period - the hash has the following
    structure:

            measurement_period_1_begin_timestamp => {
              begin_timestamp       => a timestamp marking the beginning of the measurement period in seconds since epoch,
              end_timestamp         => a timestamp marking the ending of the measurement period in seconds since epoch,
              begin_date            => a human-readable timestamp marking the beginning of the measurement period (YYYY-MM-DD HH:MM:SS TZ),
              end_date              => a human-readable timestamp marking the ending of the measurement period (YYYY-MM-DD HH:MM:SS TZ),
              cpu_usage             => the total CPU usage for the measurement period
            },
            measurement_period_2_begin_timestamp => {
              ...
            },
            ...
            measurement_period_n_begin_timestamp => {
              ...
            }

   overall_cpu_usage_current_day
    Returns a nested hash containing statistics for the overall CPU usage
    for the previous daily period - the hash has the same structure as
    detailed in the overall_cpu_usage_current_hour above.

   overall_cpu_usage_current_week
    Returns a nested hash containing statistics for the overall CPU usage
    for the previous weekly period - the hash has the same structure as
    detailed in the overall_cpu_usage_current_hour above.

   overall_cpu_usage_current_hour_raw
    Returns a scalar containing statistics for the overall CPU usage for the
    previous hourly period as retrieved directly from the reporting API.

    This method may be useful if you wish to process the raw data retrieved
    from the API yourself.

   overall_cpu_usage_current_day_raw
    Returns a scalar containing statistics for the overall CPU usage for the
    previous daily period as retrieved directly from the reporting API.

    This method may be useful if you wish to process the raw data retrieved
    from the API yourself.

   overall_cpu_usage_current_week_raw
    Returns a scalar containing statistics for the overall CPU usage for the
    previous weekly period as retrieved directly from the reporting API.

    This method may be useful if you wish to process the raw data retrieved
    from the API yourself.

   top_incoming_virus_types_detected_current_hour
    This method returns a nested hash containing statistics for the top
    incoming virus types detected in the previous hourly period - the hash
    has the following structure:

            measurement_period_1_begin_timestamp => {
              begin_timestamp       => a timestamp marking the beginning of the measurement period in seconds since epoch,
              end_timestamp         => a timestamp marking the ending of the measurement period in seconds since epoch,
              begin_date            => a human-readable timestamp marking the beginning of the measurement period (YYYY-MM-DD HH:MM:SS TZ),
              end_date              => a human-readable timestamp marking the ending of the measurement period (YYYY-MM-DD HH:MM:SS TZ),
              messages              => the number of messages detected for the measurement period,
              virus_type            => a comma-seperated list of the incoming virus types detected for this measurement period
            },
            measurement_period_2_begin_timestamp => {
              ...
            },
            ...
            measurement_period_n_begin_timestamp => {
              ...
            }

   top_incoming_virus_types_detected_current_day
    Returns a nested hash containing statistics for the top incoming virus
    types detected in the previous daily period - the hash has the same
    structure as detailed in the
    top_incoming_virus_types_detected_current_hour above.

   top_incoming_virus_types_detected_current_week
    Returns a nested hash containing statistics for the top incoming virus
    types detected in the previous weekly period - the hash has the same
    structure as detailed in the
    top_incoming_virus_types_detected_current_hour above.

   top_incoming_virus_types_detected_current_day_raw
    Returns a scalar containing statistics for the top incoming virus types
    detected for the previous daily period as retrieved directly from the
    reporting API.

    This method may be useful if you wish to process the raw data retrieved
    from the API yourself.

   top_incoming_virus_types_detected_current_hour_raw
    Returns a scalar containing statistics for the top incoming virus types
    detected in the previous hourly period as retrieved directly from the
    reporting API.

    This method may be useful if you wish to process the raw data retrieved
    from the API yourself.

   top_incoming_virus_types_detected_current_week_raw
    Returns a scalar containing statistics for the top incoming virus types
    detected for the previous weekly period as retrieved directly from the
    reporting API.

    This method may be useful if you wish to process the raw data retrieved
    from the API yourself.

   top_outgoing_content_filter_matches_current_hour
    This method returns a nested hash containing statistics for the top
    outgoing content filter matches for the previous hourly period - the
    hash has the following structure:

            measurement_period_1_begin_timestamp => {
              begin_timestamp       => a timestamp marking the beginning of the measurement period in seconds since epoch,
              end_timestamp         => a timestamp marking the ending of the measurement period in seconds since epoch,
              begin_date            => a human-readable timestamp marking the beginning of the measurement period (YYYY-MM-DD HH:MM:SS TZ),
              end_date              => a human-readable timestamp marking the ending of the measurement period (YYYY-MM-DD HH:MM:SS TZ),
              content_filter        => the name of the content filter,
              messages              => the number of outgoing messages matched by the content filter in the previous hour period
            },
            measurement_period_2_begin_timestamp => {
              ...
            },
            ...
            measurement_period_n_begin_timestamp => {
              ...
            }

   top_outgoing_content_filter_matches_current_day
    Returns a nested hash containing statistics for the top outgoing content
    filter matches for the previous daily period - the hash has the same
    structure as detailed in the
    top_outgoing_content_filter_matches_current_hour above.

   top_outgoing_content_filter_matches_current_week
    Returns a nested hash containing statistics for the top outgoing content
    filter matches for the previous weekly period - the hash has the same
    structure as detailed in the
    top_outgoing_content_filter_matches_current_hour above.

   top_outgoing_content_filter_matches_current_hour_raw
    Returns a scalar containing statistics for the top outgoing content
    content filter matches for the previous hourly period as retrieved
    directly from the reporting API.

    This method may be useful if you wish to process the raw data retrieved
    from the API yourself.

   top_outgoing_content_filter_matches_current_day_raw
    Returns a nested hash containing statistics for the top outgoing content
    filter matches for the previous daily period as retrieved directly from
    the reporting API.

    This method may be useful if you wish to process the raw data retrieved
    from the API yourself.

   top_outgoing_content_filter_matches_current_week_raw
    Returns a scalar containing statistics for the average time a message
    spent in the workqueue for the previous weekly period as retrieved
    directly from the reporting API.

    This method may be useful if you wish to process the raw data retrieved
    from the API yourself.

   top_incoming_content_filter_matches_current_hour
    This method returns a nested hash containing statistics for the top
    incoming content filter matches for the previous hourly period - the
    hash has the following structure:

            measurement_period_1_begin_timestamp => {
              begin_timestamp       => a timestamp marking the beginning of the measurement period in seconds since epoch,
              end_timestamp         => a timestamp marking the ending of the measurement period in seconds since epoch,
              begin_date            => a human-readable timestamp marking the beginning of the measurement period (YYYY-MM-DD HH:MM:SS TZ),
              end_date              => a human-readable timestamp marking the ending of the measurement period (YYYY-MM-DD HH:MM:SS TZ),
              content_filter        => the name of the content filter,
              messages              => the number of incoming messages matched by the content filter in the previous hour period
            },
            measurement_period_2_begin_timestamp => {
              ...
            },
            ...
            measurement_period_n_begin_timestamp => {
              ...
            }

   top_incoming_content_filter_matches_current_day
    Returns a nested hash containing statistics for the top incoming content
    filter matches for the previous daily period - the hash has the same
    structure as detailed in the
    top_incoming_content_filter_matches_current_hour above.

   top_incoming_content_filter_matches_current_week
    Returns a nested hash containing statistics for the top incoming content
    filter matches for the previous weekly period - the hash has the same
    structure as detailed in the
    top_incoming_content_filter_matches_current_hour above.

   top_incoming_content_filter_matches_current_hour_raw
    Returns a scalar containing statistics for the top incoming content
    content filter matches for the previous hourly period as retrieved
    directly from the reporting API.

    This method may be useful if you wish to process the raw data retrieved
    from the API yourself.

   top_incoming_content_filter_matches_current_day_raw
    Returns a scalar containing statistics for the top incoming content
    content filter matches for the previous daily period as retrieved
    directly from the reporting API.

    This method may be useful if you wish to process the raw data retrieved
    from the API yourself.

   top_incoming_content_filter_matches_current_week_raw
    Returns a scalar containing statistics for the top incoming content
    content filter matches for the previous weekly period as retrieved
    directly from the reporting API.

    This method may be useful if you wish to process the raw data retrieved
    from the API yourself.

   total_incoming_connections_current_hour
    This method returns a nested hash containing statistics for the total
    number of incoming connections for the previous hourly period - the hash
    has the following structure:

            measurement_period_1_begin_timestamp => {
              begin_timestamp       => a timestamp marking the beginning of the measurement period in seconds since epoch,
              end_timestamp         => a timestamp marking the ending of the measurement period in seconds since epoch,
              begin_date            => a human-readable timestamp marking the beginning of the measurement period (YYYY-MM-DD HH:MM:SS TZ),
              end_date              => a human-readable timestamp marking the ending of the measurement period (YYYY-MM-DD HH:MM:SS TZ),
              connections           => the total number of connections for the measurement period
            },
            measurement_period_2_begin_timestamp => {
              ...
            },
            ...
            measurement_period_n_begin_timestamp => {
              ...
            }

   total_incoming_connections_current_day
    Returns a nested hash containing statistics for the total number of
    incoming connections for the previous daily period - the hash has the
    same structure as detailed in the total_incoming
    connections_current_hour above.

   total_incoming_connections_current_week
    Returns a nested hash containing statistics for the total number of
    incoming connections for the previous weekly period - the hash has the
    same structure as detailed in the total_incoming
    connections_current_hour above.

   total_incoming_connections_current_hour_raw
    Returns a scalar containing statistics for the total number of incoming
    connections for the previous hourly period as retrieved directly from
    the reporting API.

    This method may be useful if you wish to process the raw data retrieved
    from the API yourself.

   total_incoming_connections_current_day_raw
    Returns a scalar containing statistics for the total number of incoming
    connections for the previous daily period as retrieved directly from the
    reporting API.

    This method may be useful if you wish to process the raw data retrieved
    from the API yourself.

   total_incoming_connections_current_week_raw
    Returns a scalar containing statistics for the total number of incoming
    connections for the previous weekly period as retrieved directly from
    the reporting API.

    This method may be useful if you wish to process the raw data retrieved
    from the API yourself.

   total_incoming_message_size_current_hour
    This method returns a nested hash containing statistics for the total
    incoming message size in bytes for the previous hourly period - the hash
    has the following structure:

            measurement_period_1_begin_timestamp => {
              begin_timestamp       => a timestamp marking the beginning of the measurement period in seconds since epoch,
              end_timestamp         => a timestamp marking the ending of the measurement period in seconds since epoch,
              begin_date            => a human-readable timestamp marking the beginning of the measurement period (YYYY-MM-DD HH:MM:SS TZ),
              end_date              => a human-readable timestamp marking the ending of the measurement period (YYYY-MM-DD HH:MM:SS TZ),
              message_size          => the total incoming message size in bytes for the measurement period
            },
            measurement_period_2_begin_timestamp => {
              ...
            },
            ...
            measurement_period_n_begin_timestamp => {
              ...
            }

   total_incoming_message_size_current_day
    Returns a nested hash containing statistics for the total incoming
    message size in bytes for the previous daily period - the hash has the
    same structure as detailed in the
    total_incoming_message_size_current_hour above.

   total_incoming_message_size_current_week
    Returns a nested hash containing statistics for the total incoming
    message size in bytes for the previous weekly period - the hash has the
    same structure as detailed in the
    total_incoming_message_size_current_hour above.

   total_incoming_message_size_current_hour_raw
    Returns a scalar containing statistics for the total incoming message
    size in bytes for the previous hourly period as retrieved directly from
    the reporting API.

    This method may be useful if you wish to process the raw data retrieved
    from the API yourself.

   total_incoming_message_size_current_day_raw
    Returns a scalar containing statistics for the total incoming message
    size in bytes for the previous daily period as retrieved directly from
    the reporting API.

    This method may be useful if you wish to process the raw data retrieved
    from the API yourself.

   total_incoming_message_size_current_week_raw
    Returns a scalar containing statistics for the total incoming message
    size in bytes for the previous weekly period as retrieved directly from
    the reporting API.

    This method may be useful if you wish to process the raw data retrieved
    from the API yourself.

   total_incoming_messages_current_hour
    This method returns a nested hash containing statistics for the total
    number of incoming messages for the previous hourly period - the hash
    has the following structure:

            measurement_period_1_begin_timestamp => {
              begin_timestamp       => a timestamp marking the beginning of the measurement period in seconds since epoch,
              end_timestamp         => a timestamp marking the ending of the measurement period in seconds since epoch,
              begin_date            => a human-readable timestamp marking the beginning of the measurement period (YYYY-MM-DD HH:MM:SS TZ),
              end_date              => a human-readable timestamp marking the ending of the measurement period (YYYY-MM-DD HH:MM:SS TZ),
              messages              => the total number of incoming messages for the measurement period
            },
            measurement_period_2_begin_timestamp => {
              ...
            },
            ...
            measurement_period_n_begin_timestamp => {
              ...
            }

   total_incoming_messages_current_day
    Returns a nested hash containing statistics for the total number of
    incoming messages for the previous daily period - the hash has the same
    structure as detailed in the
    total_number_of_incoming_messages_current_hour above.

   total_incoming_messages_current_week
    Returns a nested hash containing statistics for the total number of
    incoming messages for the previous weekly period - the hash has the same
    structure as detailed in the
    total_number_of_incoming_messages_current_hour above.

   total_incoming_messages_current_hour_raw
    Returns a scalar containing statistics for the total number of incoming
    messages for the previous hourly period as retrieved directly from the
    reporting API.

    This method may be useful if you wish to process the raw data retrieved
    from the API yourself.

   total_incoming_messages_current_day_raw
    Returns a scalar containing statistics for the total number of incoming
    messages for the previous daily period as retrieved directly from the
    reporting API.

    This method may be useful if you wish to process the raw data retrieved
    from the API yourself.

   total_incoming_messages_current_week_raw
    Returns a scalar containing statistics for the total number of incoming
    messages for the previous weekly period as retrieved directly from the
    reporting API.

    This method may be useful if you wish to process the raw data retrieved
    from the API yourself.

   total_outgoing_connections_current_hour
    This method returns a nested hash containing statistics for the total
    number of outgoing connections for the previous hourly period - the hash
    has the following structure:

            measurement_period_1_begin_timestamp => {
              begin_timestamp       => a timestamp marking the beginning of the measurement period in seconds since epoch,
              end_timestamp         => a timestamp marking the ending of the measurement period in seconds since epoch,
              begin_date            => a human-readable timestamp marking the beginning of the measurement period (YYYY-MM-DD HH:MM:SS TZ),
              end_date              => a human-readable timestamp marking the ending of the measurement period (YYYY-MM-DD HH:MM:SS TZ),
              connections           => the total number of outgoing connections for the measurement period
            },
            measurement_period_2_begin_timestamp => {
              ...
            },
            ...
            measurement_period_n_begin_timestamp => {
              ...
            }

   total_outgoing_connections_current_day
    Returns a nested hash containing statistics for the total number of
    outgoing connections for the previous daily period - the hash has the
    same structure as detailed in the
    total_number_outgoing_connections_current_hour above.

   total_outgoing_connections_current_week
    Returns a nested hash containing statistics for the total number of
    outgoing connections for the previous weekly period - the hash has the
    same structure as detailed in the
    total_number_outgoing_connections_current_hour above.

   total_outgoing_connections_current_hour_raw
    Returns a scalar containing statistics for the total number of outgoing
    connections for the previous hourly period as retrieved directly from
    the reporting API.

    This method may be useful if you wish to process the raw data retrieved
    from the API yourself.

   total_outgoing_connections_current_day_raw
    Returns a scalar containing statistics for the total number of outgoing
    connections for the previous daily period as retrieved directly from the
    reporting API.

    This method may be useful if you wish to process the raw data retrieved
    from the API yourself.

   total_outgoing_connections_current_week_raw
    Returns a scalar containing statistics for the total number of outgoing
    connections for the previous weekly period as retrieved directly from
    the reporting API.

    This method may be useful if you wish to process the raw data retrieved
    from the API yourself.

   total_outgoing_message_size_current_hour
    This method returns a nested hash containing statistics for the total
    outgoing message size in bytes for the previous hourly period - the hash
    has the following structure:

            measurement_period_1_begin_timestamp => {
              begin_timestamp       => a timestamp marking the beginning of the measurement period in seconds since epoch,
              end_timestamp         => a timestamp marking the ending of the measurement period in seconds since epoch,
              begin_date            => a human-readable timestamp marking the beginning of the measurement period (YYYY-MM-DD HH:MM:SS TZ),
              end_date              => a human-readable timestamp marking the ending of the measurement period (YYYY-MM-DD HH:MM:SS TZ),
              message_size          => the total outgoing message size in bytes for the measurement period
            },
            measurement_period_2_begin_timestamp => {
              ...
            },
            ...
            measurement_period_n_begin_timestamp => {
              ...
            }

   total_outgoing_message_size_current_day
    Returns a nested hash containing statistics for the total outgoing
    message size in bytes for the previous daily period - the hash has the
    same structure as detailed in the
    total_outgoing_message_size_current_hour above.

   total_outgoing_message_size_current_week
    Returns a nested hash containing statistics for the total outgoing
    message size in bytes for the previous weekly period - the hash has the
    same structure as detailed in the
    total_outgoing_message_size_current_hour above.

   total_outgoing_message_size_current_hour_raw
    Returns a scalar containing statistics for the total outgoing message
    size in bytes for the previous hourly period as retrieved directly from
    the reporting API.

    This method may be useful if you wish to process the raw data retrieved
    from the API yourself.

   total_outgoing_message_size_current_day_raw
    Returns a scalar containing statistics for the total outgoing message
    size for the previous daily period as retrieved directly from the
    reporting API.

    This method may be useful if you wish to process the raw data retrieved
    from the API yourself.

   total_outgoing_message_size_current_week_raw
    Returns a scalar containing statistics for the total outgoing message
    size for the previous weekly period as retrieved directly from the
    reporting API.

    This method may be useful if you wish to process the raw data retrieved
    from the API yourself.

   total_outgoing_messages_current_hour
    This method returns a nested hash containing statistics for the total
    outgoing number of messages for the previous hourly period - the hash
    has the following structure:

            measurement_period_1_begin_timestamp => {
              begin_timestamp       => a timestamp marking the beginning of the measurement period in seconds since epoch,
              end_timestamp         => a timestamp marking the ending of the measurement period in seconds since epoch,
              begin_date            => a human-readable timestamp marking the beginning of the measurement period (YYYY-MM-DD HH:MM:SS TZ),
              end_date              => a human-readable timestamp marking the ending of the measurement period (YYYY-MM-DD HH:MM:SS TZ),
              messages              => the total number of outgoing messages for the measurement period
            },
            measurement_period_2_begin_timestamp => {
              ...
            },
            ...
            measurement_period_n_begin_timestamp => {
              ...
            }

   total_outgoing_messages_current_day
    Returns a nested hash containing statistics for the total number of
    outgoing messages for the previous daily period - the hash has the same
    structure as detailed in the
    total_number_of_outgoing_messages_current_hour above.

   total_outgoing_messages_current_week
    Returns a nested hash containing statistics for the total number of
    outgoing messages for the previous weekly period - the hash has the same
    structure as detailed in the
    total_number_of_outgoing_messages_current_hour above.

   total_outgoing_messages_current_hour_raw
    Returns a scalar containing statistics for the total number of outgoing
    messages for the previous hourly period as retrieved directly from the
    reporting API.

    This method may be useful if you wish to process the raw data retrieved
    from the API yourself.

   total_outgoing_messages_current_day_raw
    Returns a scalar containing statistics for the total number of outgoing
    messages for the previous daily period as retrieved directly from the
    reporting API.

    This method may be useful if you wish to process the raw data retrieved
    from the API yourself.

   total_outgoing_messages_current_week_raw
    Returns a scalar containing statistics for the total number of outgoing
    messages for the previous weekly period as retrieved directly from the
    reporting API.

    This method may be useful if you wish to process the raw data retrieved
    from the API yourself.

   internal_user_details_current_hour
    This method returns a nested hash containing details of the mail sent by
    each internal user for the previous hourly period - the hash has the
    following structure:

            user1@domain.com => {
                    begin_date                              => a human-readable timestamp marking the beginning of the measurement period (YYYY-MM-DD HH:MM:SS TZ),
                    begin_timestamp                         => a timestamp marking the beginning of the measurement period in seconds since epoch,
                    end_date                                => a human-readable timestamp marking the ending of the measurement period (YYYY-MM-DD HH:MM:SS TZ),
                    end_timestamp                           => a timestamp marking the ending of the measurement period in seconds since epoch,
                    incoming_clean                          => the number of incoming clean messages sent to this user,
                    incoming_content_filter_matches         => the number of incoming messages sent to this user matching ian incoming content filter,
                    incoming_spam_detected                  => the number of incoming messages sent to this user that were detected as spam,
                    incoming_stopped_by_content_filter      => the number of incoming messages sent to this user that were stopped by content filtering,
                    incoming_virus_detected                 => the number of incoming messages sent to this user that were detected as virii,
                    internal_user                           => the email address of the internal user,
                    outgoing_clean                          => the number of outgoing clean messages sent by this user,
                    outgoing_content_filter_matches         => the number of outgoing messages sent by this user matching outgoing content filters,
                    outgoing_spam_detected                  => the number of outgoing messages sent by this user that were detected as spam,
                    outgoing_stopped_by_content_filter      => the number of outgoing messages sent by this user stopped by outgoing content filters,
                    outgoing_virus_detected                 => the number of outgoing messages sent by this user matching outgoing virus filters
            },
            user2@domain.com => {
                    ...
            },
            ...
            userN@domain.com => {
                    ...
            }

   internal_user_details_current_day
    Returns a nested hash containing details of the mail sent by each
    internal user for the previous daily period - the hash has the same
    structure as detailed in the internal_user_details_current_hour above.

   internal_user_details_current_week
    Returns a nested hash containing details of the mail sent by each
    internal user for the previous weekly period - the hash has the same
    structure as detailed in the internal_user_details_current_hour above.

   internal_user_details_current_hour_raw
    Returns a scalar containing details of the mail sent by each internal
    user for the previous hourly period as retrieved directly from the
    reporting API.

    This method may be useful if you wish to process the raw data retrieved
    from the API yourself.

   internal_user_details_current_day_raw
    Returns a scalar containing details of the mail sent by each internal
    user for the previous daily period as retrieved directly from the
    reporting API.

    This method may be useful if you wish to process the raw data retrieved
    from the API yourself.

   internal_user_details_current_week_raw
    Returns a scalar containing details of the mail sent by each internal
    user for the previous weekly period as retrieved directly from the
    reporting API.

    This method may be useful if you wish to process the raw data retrieved
    from the API yourself.

   content_filter_detail_current_hour ( { filter_name => $filter_name } )
    Given an anonymous hash containing the key 'filter_name' where the value
    is a valid content filter name defined on the target device, this method
    returns a nested hash containing details of the content filter
    statistics for the previous hourly period - the hash has the following
    structure:

            measurement_period_1_begin_timestamp => {
              begin_timestamp       => a timestamp marking the beginning of the measurement period in seconds since epoch,
              end_timestamp         => a timestamp marking the ending of the measurement period in seconds since epoch,
              begin_date            => a human-readable timestamp marking the beginning of the measurement period (YYYY-MM-DD HH:MM:SS TZ),
              end_date              => a human-readable timestamp marking the ending of the measurement period (YYYY-MM-DD HH:MM:SS TZ),
              key                   => the user-specified name of the content filter that was matched,
              internal_user         => the email address of the internal user sending the email matching the content filter,
              messages              => the total number of messages matching this content_filter for the measurement period
            },
            measurement_period_1_begin_timestamp => {

   content_filter_detail_current_day ( { filter_name => $filter_name } )
    Given an anonymous hash containing the key 'filter_name' where the value
    is a valid content filter name defined on the target device, this method
    returns a nested hash containing details of the content filter
    statistics for the previous daily period - the hash has the same
    structure as detailed in the content_filter_detail_current_hour method.

   content_filter_detail_current_week ( { filter_name => $filter_name } )
    Given an anonymous hash containing the key 'filter_name' where the value
    is a valid content filter name defined on the target device, this method
    returns a nested hash containing details of the content filter
    statistics for the previous weekly period - the hash has the same
    structure as detailed in the content_filter_detail_current_hour method.

   content_filter_detail_current_hour_raw ( { filter_name => $filter_name } )
    Returns a scalar containing details of the content filter statistics for
    the previous hourly period as retrieved directly from the reporting API.

    This method may be useful if you wish to process the raw data retrieved
    from the API yourself.

   content_filter_detail_current_day_raw ( { filter_name => $filter_name } )
    Returns a scalar containing details of the content filter statistics for
    the previous daily period as retrieved directly from the reporting API.

    This method may be useful if you wish to process the raw data retrieved
    from the API yourself.

   content_filter_detail_current_week_raw ( { filter_name => $filter_name } )
    Returns a scalar containing details of the content filter statistics for
    the previous weekly period as retrieved directly from the reporting API.

    This method may be useful if you wish to process the raw data retrieved
    from the API yourself.

   outgoing_delivery_status_current_hour
    Returns a nested hash containing details of outgoing delivery status
    statistics for the previous hourly period indexed by destination domain
    - the hash has the following structure:

            domain-1.com => {
              active_recipients     => the number of messages currently pending delivery for this domain,
              connections_out       => the number of active outbound connections to this domain,
              delivered recipients  => the number of messages delivered to this domain,
              destination_domain    => the destination domain name (this is the same as the hash key),
              hard_bounced          => the number of messages sent to this domain that were hard bounced,
              latest_host_status    => the last recorded host status (e.g. up or down),
              soft_bounced          => the number of messages sent to this domain that were soft bounced,
            },
            domain-2.com => {
              ...
            },
            ...
            domain-n.com => {
              ...
            }

   outgoing_delivery_status_current_day
    Returns a nested hash containing details of outgoing delivery status
    statistics for the previous daily period indexed by destination domain -
    the hash has the same structure as the hash returned in the
    outgoing_delivery_status_current_hour method.

   outgoing_delivery_status_current_week
    Returns a nested hash containing details of outgoing delivery status
    statistics for the previous weekly period indexed by destination domain
    - the hash has the same structure as the hash returned in the
    outgoing_delivery_status_current_hour method.

   outgoing_delivery_status_current_hour_raw
    Returns a scalar containing details of outgoing delivery status
    statistics for the previous hourly period as returned directly from the
    API.

    This method may be useful if you wish to process the raw data retrieved
    from the API yourself.

   outgoing_delivery_status_current_day_raw
    Returns a scalar containing details of outgoing delivery status
    statistics for the previous daily period as returned directly from the
    API.

    This method may be useful if you wish to process the raw data retrieved
    from the API yourself.

   outgoing_delivery_status_current_week_raw
    Returns a scalar containing details of outgoing delivery status
    statistics for the previous weekly period as returned directly from the
    API.

    This method may be useful if you wish to process the raw data retrieved
    from the API yourself.

AUTHOR
    Luke Poskitt, "<ltp at cpan.org>"

BUGS
    Please report any bugs or feature requests to "bug-cisco-ironport at
    rt.cpan.org", or through the web interface at
    <http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Cisco-IronPort>. I will
    be notified, and then you'll automatically be notified of progress on
    your bug as I make changes.

SUPPORT
    You can find documentation for this module with the perldoc command.

        perldoc Cisco::IronPort

    You can also look for information at:

    *   RT: CPAN's request tracker (report bugs here)

        <http://rt.cpan.org/NoAuth/Bugs.html?Dist=Cisco-IronPort>

    *   AnnoCPAN: Annotated CPAN documentation

        <http://annocpan.org/dist/Cisco-IronPort>

    *   CPAN Ratings

        <http://cpanratings.perl.org/d/Cisco-IronPort>

    *   Search CPAN

        <http://search.cpan.org/dist/Cisco-IronPort/>

LICENSE AND COPYRIGHT
    Copyright 2013 Luke Poskitt.

    This program is free software; you can redistribute it and/or modify it
    under the terms of either: the GNU General Public License as published
    by the Free Software Foundation; or the Artistic License.

    See http://dev.perl.org/licenses/ for more information.

