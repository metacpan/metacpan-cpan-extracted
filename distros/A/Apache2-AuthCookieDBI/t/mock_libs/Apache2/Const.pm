package Apache2::Const;

sub OK                   {1}
sub HTTP_FORBIDDEN       {2}
sub SERVER_ERROR         {3}
sub LOG_EMERG            {4}
sub LOG_ALERT            {5}
sub LOG_CRIT             {6}
sub LOG_ERR              {7}
sub LOG_WARNING          {8}
sub LOG_NOTICE           {9}
sub LOG_INFO             {10}
sub LOG_DEBUG            {11}
sub AUTHZ_GRANTED        {2401}
sub AUTHZ_DENIED         {2402}
sub AUTHZ_DENIED_NO_USER {2403}
sub AUTHZ_GENERAL_ERROR  {2404}

1;
