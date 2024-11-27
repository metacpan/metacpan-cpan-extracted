# App-PasswordManager

`App::PasswordManager` is a command-line password manager written in Perl. It allows users to securely add, list, edit, remove, and copy passwords. The passwords are stored in an encrypted format using PBKDF2 and saved in a JSON file located in the user's home directory.

## Features

- **Add Password**: Add a new password entry for a specific login.
- **List Passwords**: Display a list of all stored logins.
- **Edit Password**: Edit the password for an existing login.
- **Remove Password**: Delete a password entry for a specific login.
- **Copy to Clipboard**: Copy the password to the clipboard for easy use.
- **Encrypted Storage**: Passwords are securely stored in an encrypted format in a JSON file in the user's home directory.

## Installation

You can install `App::PasswordManager` manually.

### Manual Installation

1. Clone or download the repository.
2. Navigate to the project directory.
3. Run the following commands to build and install the module:

```
perl Makefile.PL
make
sudo make install
```

## Usage

### Command-Line Tool

After installation, you can use the password manager via the command-line interface. The following options are available:

```
password_manager --add <login> <password>       # Add a new password
password_manager --list                         # List all passwords
password_manager --edit <login> <new_password>  # Edit a password
password_manager --remove <login>               # Remove a password
password_manager --copy <login>                 # Copy the password to the clipboard
```

For example, to add a password:

```
password_manager --add "user1" "mysecretpassword"
```

To list all passwords:

```
password_manager --list
```

To edit a password:

```
password_manager --edit "user1" "newpassword"
```

To remove a password:

```
password_manager --remove "user1"
```

To copy a password to the clipboard:

```
password_manager --copy "user1"
```

## Dependencies

- `Crypt::PBKDF2`
- `File::HomeDir`
- `File::Spec`
- `JSON`

You can install the necessary dependencies via `cpanm`:

```
cpanm Crypt::PBKDF2 File::HomeDir File::Spec JSON
```

## Contributing

1. Fork the repository.
2. Create a new branch (`git checkout -b feature-branch`).
3. Make your changes.
4. Commit your changes (`git commit -am 'Add new feature'`).
5. Push to the branch (`git push origin feature-branch`).
6. Create a merge request.

## License

This project is licensed under the MIT License - see the [MIT](https://gitlab.com/olooeez/app-passwordmanager/-/blob/main/LICENSE) file for details.
