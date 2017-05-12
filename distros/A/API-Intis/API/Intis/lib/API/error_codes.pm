package error_codes;
use Modern::Perl;
use Switch;

sub get_name_from_code  {
    my $code = shift;
    my $descr;
    switch ($code // "")
    {
        #        code keys
        case "000"       { $descr = 'Service unavailable'; }
        case "1"         { $descr = 'Signature not specified';  }
        case "2"         { $descr = 'Login not specified';  }
        case "3"         { $descr = 'Text not specified';  }
        case "4"         { $descr = 'Phone number not specified';  }
        case "5"         { $descr = 'Sender not specified';  }
        case "6"         { $descr = 'Invaild signature';  }
        case "7"         { $descr = 'Invalid login';  }
        case "8"         { $descr = 'Invalid sender name';  }
        case "9"         { $descr = 'Sender name not registered';  }
        case "10"        { $descr = 'Sender name not approved';  }
        case "11"        { $descr = 'There are forbidden words in the text';  }
        case "12"        { $descr = 'Error in SMS sending';  }
        case "13"        { $descr = 'Phone number is in the stop list. SMS sending to this number is forbidden.';  }
        case "14"        { $descr = 'There are more than 50 numbers in the request';  }
        case "15"        { $descr = 'List not specified';  }
        case "16"        { $descr = 'Invalid phone number';  }
        case "17"        { $descr = 'SMS ID not specified';  }
        case "18"        { $descr = 'Status not obtained';  }
        case "19"        { $descr = 'Empty response';  }
        case "20"        { $descr = 'The number already exists';  }
        case "21"        { $descr = 'No name';  }
        case "22"        { $descr = 'Template already exists';  }
        case "23"        { $descr = 'Month not specifies (Format: YYYY-MM)';  }
        case "24"        { $descr = 'Timestamp not specified';  }
        case "25"        { $descr = 'Error in access to the list';  }
        case "26"        { $descr = 'There are no numbers in the list';  }
        case "27"        { $descr = 'No valid numbers';  }
        case "28"        { $descr = 'Date of start not specified (Format: YYYY-MM-DD)';  }
        case "29"        { $descr = 'Date of end not specified (Format: YYYY-MM-DD)';  }
        case "30"        { $descr = 'No date (format: YYYY-MM-DD)';  }
        case "31"        { $descr = 'Closing direction to the user';  }
        case "32"        { $descr = 'Not enough money';  }
        #        for all
        else              { $descr =  "all right"; $code = "999";}

    }
    return ($code, $descr);

};

1;