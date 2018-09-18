# App::Git::IssueManager

App::Git::IssueManager is a Perl Application for using git as an issue store creating a
**distributed issue management system**.
It uses the *Git::IssueManager* Module to implement all management fu.

## EXAMPLE
```bash
git issue init -t "TST"   # initialize the issue management in an existing git reposittory
git issue add -s "Bug1" -d "This is a bug"  # add an issue
git issue list            # list all open issues
git issue                 # list all available commands
```

## MOTIVATION

Issue management is an essential part in modern software engineering. In most cases tools
like *jira* or *github* are used for this task. The central nature of these tools is a large
disadvantage if you are often on the road. Furthermore if you are using *git* for version control you have everything available for **distributed issue management**.

### Advantages

*   save your issues within your project
*   manage issues on the road, without internet access
*   write your own scripts for issue management

### Disadvantages

*   no easy way to let users add issues without pull request yet
*   not all functions implemented yet

## FEATURES

*   add issues
*   list issues
*   assign workers to an issue
*   start and close issues
*   delete issues
