# Security Policy

## Supported Versions

I only provide security updates for the **latest release** of this project.  
Older releases are not maintained and may contain unpatched vulnerabilities.  
Users are strongly encouraged to stay up to date with the latest CPAN version.  

## Reporting a Vulnerability

If you discover a security vulnerability, please report it **privately and responsibly**.  
Do **not** open a public GitHub issue.

Use the following secure contact form to make contact.
👉 [https://www.nigelhorne.com/cgi-bin/email_app.pl](https://www.nigelhorne.com/cgi-bin/email_app.pl)

After making contact you will then be able to file a report.
When reporting, please include:

- A clear description of the issue  
- Affected versions (Perl version and module version)  
- Proof-of-concept exploit or test case (if possible)  
- Environment details (OS, Perl version, dependencies)  

I try to acknowledge reports within **48 hours** and aim to provide a fix or remediation guidance within **30 days**,
where possible.

## Disclosure Policy

- Reports must remain private until a fix has been released.  
- I will coordinate with you on disclosure timing once a patch is available.  
- Public disclosure before a patch is released is discouraged and may put users at risk.  

## Scope

I only accept reports for **security issues within this repository**.  
Vulnerabilities in third-party CPAN modules or other dependencies should be reported upstream.  

## Acknowledgement

Valid security reporters will be:  
- Credited in the project’s `Changes`/`Changelog` file  
- Listed as a contributor in the Git history where possible  

I greatly appreciate responsible disclosure and value the contributions of the security community.  

## Known Risks & Considerations

Users of Perl-based projects should be aware of common risks:

- **Taint Mode (`-T`)**: Running without taint mode may allow unsafe data to influence program execution.  
- **Input Validation**: Be cautious of unvalidated external input, especially in CGI/HTTP contexts.  
- **Deserialization**: Avoid using `Storable::thaw`, `eval`, or similar functions on untrusted input, as this can lead to arbitrary code execution.  
- **External Commands**: If the software invokes system commands, ensure parameters are properly sanitized to prevent command injection.  
- **Dependencies**: While this project only maintains its own code, insecure CPAN modules in your environment may also expose risks.  
