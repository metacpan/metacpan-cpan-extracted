# SeismicUnixGui
SeismicUnixGui (alpha) is a graphical user interface (GUI) to select parameters for Seismic Unix (SU) modules. 
Seismic Unix (Stockwell, 1999) is a widely distributed free software package for processing seismic reflection
and signal processing.  Perl/Tk is a mature, well-documented and free object-oriented graphical user interface for Perl.  
In a classroom environment, shell scripting of SU modules engages students and helps focus on the theoretical limitations
and strengths of signal processing.  However, complex interactive processing stages, e.g., selection of optimal 
stacking velocities, killing bad data traces, or spectral analysis requires advanced flows beyond the scope of 
introductory classes.  In a research setting, special functionality from other free seismic processing software 
such as SioSeis (UCSD-NSF) can be incorporated readily via an object-oriented style to programming.
An object oriented approach is a first step toward efficient extensible programming of multi-step processes, 
and a simple GUI simplifies parameter selection and decision making.  Currently, in L_SU, Perl 5 packages 
wrap nearyly 300 SU modules that are used in teaching undergraduate and first-year graduate student 
classes (e.g., filtering, display, velocity analysis and stacking).  Perl packages (classes) can advantageously
add new functionality around each module and clarify parameter names for easier usage.  For example, through 
the use of methods, packages can isolate the user from repetitive control structures, as well as replace the 
names of abbreviated parameters with self-describing names.  Moose, an extension of the Perl 5 object system, 
greatly facilitates an object-oriented style.  Perl wrappers are self-documenting via Perl programming document 
markup language.  
