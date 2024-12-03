# App-Changelog

`App::Changelog` is a command-line tool written in Perl for automatically generating changelogs based on Git commit history. It allows you to create detailed or compact logs, filter specific tags, and save the changelog to a file.

## Features

- **Automatic Changelog Generation**: Generate changelogs directly from Git history.
- **Optional Compact Mode**: Choose between compact or detailed logs.
- **Tag Filtering**: Filter commits based on tags starting with a specific prefix.
- **Customizable Output File**: Specify the name of the output changelog file.

## Installation

You can install `App::Changelog` manually or from [MetaCPAN](https://metacpan.org/dist/App-Changelog).

### Manual Installation

1. Clone or download the repository.
2. Navigate to the project directory.
3. Run the following commands to install dependencies and prepare the script:

```
cpanm install --installdeps .
```

Ensure Perl and [cpanm](https://metacpan.org/dist/App-cpanminus/view/lib/App/cpanminus/fatscript.pm) are installed on your system.

### MetaCPAN

1. User [cpanm](https://metacpan.org/dist/App-cpanminus/view/lib/App/cpanminus/fatscript.pm) to install the app:

```
cpanm install App::TodoList
```

## Usage

After installation, you can run the script directly from the command line. The available options are:

```
./Changelog.pl [options]
```

### Options

```
changelog --output <output_file>     # Set the output file (default: CHANGELOG.md)
changelog --compact                  # Enable compact logs (default: enabled)
changelog --no-compact               # Disable compact mode and generate detailed logs
changelog --conventional             # Format the changelog based on Conventional Commits
changelog --filter                   # Filter tags that start with the specified prefix
```

### Examples

To generate a changelog in compact mode (default):

```
changelog
```

To save the changelog to a specific file:

```
changelog --output changelog.md
```

To generate detailed logs:

```
changelog --no-compact
```

To filter commits by tags starting with "v":

```
changelog --filter v
```

## Contributing

1. Fork the repository.
2. Create a new branch (`git checkout -b feature-branch`).
3. Make your changes.
4. Commit your changes (`git commit -am 'Add new feature'`).
5. Push to the branch (`git push origin feature-branch`).
6. Create a merge request.

## License

This project is licensed under the MIT License - see the [MIT](https://gitlab.com/olooeez/app-changelog/-/blob/main/LICENSE) file for details.
