# App-TodoList

`App::TodoList` is a simple command-line to-do list manager written in Perl. It allows users to add, list, complete, and delete tasks, and saves the tasks in a JSON file located in the user's home directory.

## Features

- **Add Task**: Add a new task to the to-do list.
- **List Tasks**: Display the current to-do list with task status (completed or not).
- **Complete Task**: Mark a specific task as completed.
- **Delete Task**: Remove a task from the list.
- **Persistent Storage**: Tasks are saved in a JSON file in the user's home directory.

## Installation

You can install `App-TodoList` manually.

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

After installation, you can use the to-do list manager via the command-line interface. The following options are available:

```
todo_list --add "Task description"      # Add a new task
todo_list --list                        # List all tasks
todo_list --complete <task_number>      # Mark a task as completed
todo_list --delete <task_number>        # Delete a task
```

For example, to add a task:

```
todo_list --add "Buy groceries"
```

To list all tasks:

```
todo_list --list
```

To mark a task as completed:

```
todo_list --complete 1  # Marks the task with index 1 as completed
```

To delete a task:

```
todo_list --delete 1  # Deletes the task with index 1
```

## Dependencies

- `JSON`
- `File::HomeDir`
- `File::Spec`

You can install the necessary dependencies via `cpanm`:

```
cpanm JSON File::HomeDir File::Spec
```

## Contributing

1. Fork the repository.
2. Create a new branch (`git checkout -b feature-branch`).
3. Make your changes.
4. Commit your changes (`git commit -am 'Add new feature'`).
5. Push to the branch (`git push origin feature-branch`).
6. Create a merge request.

## License

This project is licensed under the MIT License - see the [LICENSE](https://gitlab.com/olooeez/app-todolist/-/blob/main/LICENSE?ref_type=heads) file for details.
