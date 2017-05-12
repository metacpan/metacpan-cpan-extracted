
import org.keyczar.*;

public class TestSign {
    public static void main(String[] args) {
        KeyczarFileReader reader = new KeyczarFileReader(args[0]);
        try {
            Signer signer = new Signer(reader);
            System.out.print(signer.sign(args[1])+"\n");
            
        } catch (org.keyczar.exceptions.KeyczarException e) {
            System.out.print("ng," + e + "\n");
        }
    }
}
