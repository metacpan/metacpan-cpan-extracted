using System;
using Microsoft.Win32;

namespace RegFileTypes
{
	/// <summary>
	/// Summary description for Class1.
	/// </summary>
	class RegFileTypes
	{
		public RegFileTypes()
		{
		}

		public void Run()
		{
			RegistryKey root = Registry.ClassesRoot;
			PrintFileTypes( root );
		}

		public void PrintFileTypes( RegistryKey root )
		{
			if( root == null ) return;
			string[] subkeys = root.GetSubKeyNames();
			foreach( string subname in subkeys )
			{
				// For each key, if it starts with . then it's a file type.
				// Otherwise, ignore it.
				if( subname == null ) continue;
				if( !subname.StartsWith(".") ) continue;

				// Open the key and find its default value.
				// If no default, skip this key, since it effectively 
				// doesn't have an assigned type.
				RegistryKey subkey = root.OpenSubKey( subname );
				if( subkey == null ) continue;
				string typename = (string) subkey.GetValue( "" );
				if( typename == null ) continue; // No default value

				// If it has a value "Content Type", that's the mime type.
				string mimetype = null;
				mimetype = (string) subkey.GetValue( "Content Type" );

				// Find the descriptor type.
				RegistryKey typekey = root.OpenSubKey( typename );
				if( typekey == null ) continue;
				string displayName = (string) typekey.GetValue( "" );

				// Find the default icon.
				RegistryKey iconkey = typekey.OpenSubKey( "DefaultIcon" );
				if( iconkey == null ) continue;
				string iconname = (string) iconkey.GetValue( "" );

				// Split the icon descriptor to get the path and the resource ID.
				char[] separators = new char[1];
				separators[0] = ',';
				string[] iconparts = null;
				if( iconname != null ) 
					iconparts = iconname.Split( separators );

				string iconfile = "";
				string iconres = "";
				if( iconparts != null && iconparts.Length <= 2 )
				{
					iconfile = iconparts[0];
					if( iconparts.Length == 2 ) iconres = iconparts[1];
				}

				Console.WriteLine( "Extension:      "+subname );
				Console.WriteLine( "  Type:         "+typename );
				Console.WriteLine( "  MimeType:     "+mimetype );
				Console.WriteLine( "  DisplayName:  "+displayName );
				Console.WriteLine( "  IconDesc:     "+iconname );
				
				// Needs checking.
				//Console.WriteLine( "  Icon:         "+iconfile );
				//Console.WriteLine( "  IconResource: "+iconres );
				Console.WriteLine( "" );
			}
		}

		/// <summary>
		/// The main entry point for the application.
		/// </summary>
		[STAThread]
		static void Main(string[] args)
		{
			try
			{
				RegFileTypes types = new RegFileTypes();
				types.Run();
			}
			catch( Exception e )
			{
				Console.WriteLine( ""+e.GetType().Name+": "+e.Message );
				Console.WriteLine( e.StackTrace );
			}
		}
	}
}
