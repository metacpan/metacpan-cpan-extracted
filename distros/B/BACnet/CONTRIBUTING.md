# Contributing Guidelines

Thank you for your interest in contributing to this Perl project. To ensure consistency and maintainability across the codebase, please follow the guidelines below.

## Workflow and Version Control

1. **Always rebase before submitting a merge request.**  
   Keep your branch up to date with the main branch and use `git rebase` to maintain a clean, linear history.

2. **Report issues via Git, not CPAN.**  
   All bug reports, feature requests, and discussions must be submitted through the Git repository’s issue tracker ([https://github.com/VojtaKrenek/BACnet-Perl](https://github.com/VojtaKrenek/BACnet-Perl)). Please do not use CPAN for reporting problems.

3. **Commit message conventions**  
   Use the following prefixes when writing commit messages:  
   - `feat: description` — for new features  
   - `fix: description` — for bug fixes  

## Adding New Modules

- When adding **any new module**, create a **dedicated test file** with the for it. 
- Every test file **must use the exact same name as the module it tests**, including the full path from the `lib/BACnet` folder of the Git repository.  
  (Example: module `lib/BACnet/NewModuleFolder/Module.pm` → test file `t/NewModuleFolder/Module.pm`.)
- The only exception is `Utils.pm`, which does not require its own test file.
- Functions that involve **network communication** are exempt from required tests  
  *(although tests for them would be welcome; I simply have not yet found a clean and efficient approach to implement them).*

## Testing

- Follow the existing test structure and naming conventions.  
- Ensure tests are deterministic and do not depend on external services unless they are explicitly mocked or isolated.


Thank you for helping improve this project. Contributions following these guidelines will be reviewed promptly.


## Github link

[https://github.com/VojtaKrenek/BACnet-Perl](https://github.com/VojtaKrenek/BACnet-Perl)

