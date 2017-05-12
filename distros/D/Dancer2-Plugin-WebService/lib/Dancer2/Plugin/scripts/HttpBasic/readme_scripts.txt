scripts expecting three arguments

   username , password , comma delimitted groups that the user should be member at least to one of them

username and password are packed as hex strings to avoid shell attacks
It will print 3 lines at STDOUT

    1st line : 1 or 0   1 is for succesfull login and 0 is for a failed login
    2nd line : A message, usually the error if the login was failed
    3rd line : A comma delimited list of the defined groups that the user is member

It will search for the config file :  SCRIPT_DIRECTORY/SCRIPT_BASE_NAME.conf

    ./admins.pl 41646d696e6973747261746f72 5040737377307264 Administrators

George Mpouras
george.mpouras@yandex.com
Athens Greece , 4 October 2016